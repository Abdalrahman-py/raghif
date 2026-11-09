-- Rollback-only checks for 20261109120000_payment_and_grant_review_fixes.
begin;

create function pg_temp.as_user(uid uuid, r text default 'authenticated') returns void
  language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(uid::text, ''), false);
  execute format('set role %I', r);
end $$;

create function pg_temp.must_fail(stmt text, needle text) returns void
  language plpgsql as $$
begin
  execute stmt;
  raise exception 'expected failure containing "%" but statement succeeded: %', needle, stmt;
exception when others then
  if sqlerrm like 'expected failure containing%' then raise; end if;
  if position(lower(needle) in lower(sqlerrm)) = 0 then
    raise exception 'wrong failure for [%]: got "%", wanted "%"', stmt, sqlerrm, needle;
  end if;
end $$;

create function pg_temp.ok(ok boolean, msg text) returns void
  language plpgsql as $$
begin
  if not coalesce(ok, false) then raise exception 'check failed: %', msg; end if;
end $$;

-- Fixtures: one owner, three buyers, one store (price 3.00).
insert into auth.users (id) values
  ('a7000000-0000-0000-0000-000000000001'),
  ('a7000000-0000-0000-0000-000000000002'),
  ('a7000000-0000-0000-0000-000000000003'),
  ('a7000000-0000-0000-0000-000000000004');
insert into public.profiles (id, phone, pin_hash, name, role) values
  ('a7000000-0000-0000-0000-000000000001', 'rf-1', 'x', 'rf-owner', 'owner'),
  ('a7000000-0000-0000-0000-000000000002', 'rf-2', 'x', 'rf-buyer1', 'buyer'),
  ('a7000000-0000-0000-0000-000000000003', 'rf-3', 'x', 'rf-buyer2', 'buyer'),
  ('a7000000-0000-0000-0000-000000000004', 'rf-4', 'x', 'rf-buyer3', 'buyer');
insert into public.stores (id, name, owner_id, is_open, daily_bag_limit, bags_remaining, batch_size, bag_price) values
  ('a8000000-0000-0000-0000-000000000001', 'rf-store', 'a7000000-0000-0000-0000-000000000001', true, 5, 5, 2, 3.00);

-- 4. reserve_bag and record_scan run with an empty search_path and still work.
do $$ begin
  perform pg_temp.ok((select proconfig = array['search_path=""'] from pg_proc
                       where oid = 'public.reserve_bag(uuid, date)'::regprocedure), 'reserve_bag search_path');
  perform pg_temp.ok((select proconfig = array['search_path=""'] from pg_proc
                       where oid = 'public.record_scan(uuid, text, uuid, text)'::regprocedure), 'record_scan search_path');
end $$;

select pg_temp.as_user('a7000000-0000-0000-0000-000000000002');
-- Any date but today in Asia/Hebron is refused.
select pg_temp.must_fail($$select public.reserve_bag('a8000000-0000-0000-0000-000000000001',
  (now() at time zone 'Asia/Hebron')::date + 1)$$, 'today only');
select public.reserve_bag('a8000000-0000-0000-0000-000000000001', (now() at time zone 'Asia/Hebron')::date);
select pg_temp.as_user('a7000000-0000-0000-0000-000000000003');
select public.reserve_bag('a8000000-0000-0000-0000-000000000001', (now() at time zone 'Asia/Hebron')::date);
select pg_temp.as_user('a7000000-0000-0000-0000-000000000004');
select public.reserve_bag('a8000000-0000-0000-0000-000000000001', (now() at time zone 'Asia/Hebron')::date);
reset role;
do $$ begin
  perform pg_temp.ok((select bags_remaining = 2 from public.stores
                       where id = 'a8000000-0000-0000-0000-000000000001'), 'stock went down by three');
end $$;

select pg_temp.as_user('a7000000-0000-0000-0000-000000000001');
select public.record_scan('a8000000-0000-0000-0000-000000000001', 'invalidCode');
select pg_temp.must_fail($$select public.record_scan('a8000000-0000-0000-0000-000000000001', 'madeUp')$$, 'unknown scan outcome');

-- 1. Buyer 1 pays through the simulated wallet; buyer 2 has a real provider
--    payment (written directly, as a future provider callback would); buyer 3
--    pays nothing up front.
select pg_temp.as_user('a7000000-0000-0000-0000-000000000002');
select public.record_wallet_payment(id) from public.purchases
 where user_id = 'a7000000-0000-0000-0000-000000000002';
reset role;
insert into public.payments (purchase_id, store_id, user_id, amount, method, provider)
select id, store_id, user_id, 3.00, 'jawwal_pay', 'jawwal_pay' from public.purchases
 where user_id = 'a7000000-0000-0000-0000-000000000003';
update public.purchases set status = 'notified'
 where store_id = 'a8000000-0000-0000-0000-000000000001';

-- Before collection nothing counts as cash taken, simulated or not.
select pg_temp.as_user('a7000000-0000-0000-0000-000000000001');
do $$
declare r record;
begin
  select * into r from public.store_daily_summaries('a8000000-0000-0000-0000-000000000001', 1);
  perform pg_temp.ok(r.sold = 3 and r.collected = 0 and r.cash_total = 0, 'no cash before collection');
end $$;

-- Price rises before pickup: cash is taken at the price of the day of pickup.
reset role;
update public.stores set bag_price = 3.50 where id = 'a8000000-0000-0000-0000-000000000001';
select pg_temp.as_user('a7000000-0000-0000-0000-000000000001');
select public.collect_purchase(id) from public.purchases
 where store_id = 'a8000000-0000-0000-0000-000000000001';
reset role;
do $$ begin
  perform pg_temp.ok((select count(*) = 3 from public.payments
                       where store_id = 'a8000000-0000-0000-0000-000000000001'), 'one row per bag');
  perform pg_temp.ok((select method = 'cash' and provider is null and amount = 3.50 from public.payments
                       where user_id = 'a7000000-0000-0000-0000-000000000002'), 'simulated becomes cash');
  perform pg_temp.ok((select method = 'jawwal_pay' and provider = 'jawwal_pay' and amount = 3.00 from public.payments
                       where user_id = 'a7000000-0000-0000-0000-000000000003'), 'real wallet payment untouched');
  perform pg_temp.ok((select method = 'cash' and amount = 3.50 from public.payments
                       where user_id = 'a7000000-0000-0000-0000-000000000004'), 'unpaid becomes cash');
end $$;

-- Cash taken = the simulated bag + the unpaid bag, not the real wallet bag.
select pg_temp.as_user('a7000000-0000-0000-0000-000000000001');
do $$
declare r record;
begin
  select * into r from public.store_daily_summaries('a8000000-0000-0000-0000-000000000001', 1);
  perform pg_temp.ok(r.collected = 3 and r.cash_total = 7.00, 'cash total');
end $$;

-- 2. record_wallet_payment still refuses another buyer's booking (buyer 3
--    cannot see buyer 1's row, so pass its id directly).
reset role;
select set_config('rf.buyer1_purchase', id::text, false) from public.purchases
 where user_id = 'a7000000-0000-0000-0000-000000000002';
select pg_temp.as_user('a7000000-0000-0000-0000-000000000003');
select pg_temp.must_fail($$select public.record_wallet_payment(current_setting('rf.buyer1_purchase')::uuid)$$,
  'purchase not found');

-- 3. popular_stores is gone, so anon reads no purchase aggregate.
reset role;
do $$ begin
  perform pg_temp.ok(to_regprocedure('public.popular_stores(integer)') is null, 'popular_stores dropped');
end $$;

reset role;
rollback;
