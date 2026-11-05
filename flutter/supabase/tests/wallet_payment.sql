-- Rollback-only checks for 20261105110000_wallet_payment_record.
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

insert into auth.users (id) values
  ('c1000000-0000-0000-0000-000000000001'),
  ('c1000000-0000-0000-0000-000000000002'),
  ('c1000000-0000-0000-0000-000000000003');
insert into public.profiles (id, phone, national_id, pin_hash, name, role) values
  ('c1000000-0000-0000-0000-000000000001', 'wp-1', 'wp-n1', 'x', 'wp-owner', 'owner'),
  ('c1000000-0000-0000-0000-000000000002', 'wp-2', 'wp-n2', 'x', 'wp-buyer1', 'buyer'),
  ('c1000000-0000-0000-0000-000000000003', 'wp-3', 'wp-n3', 'x', 'wp-buyer2', 'buyer');
insert into public.stores (id, name, owner_id, is_open, daily_bag_limit, bags_remaining, batch_size, bag_price) values
  ('c2000000-0000-0000-0000-000000000001', 'wp-store', 'c1000000-0000-0000-0000-000000000001', true, 5, 5, 2, 4.50);
insert into public.purchases (id, store_id, user_id, purchase_date, batch_number, status) values
  ('c3000000-0000-0000-0000-000000000001', 'c2000000-0000-0000-0000-000000000001',
   'c1000000-0000-0000-0000-000000000002', (now() at time zone 'Asia/Hebron')::date, 1, 'notified'),
  ('c3000000-0000-0000-0000-000000000002', 'c2000000-0000-0000-0000-000000000001',
   'c1000000-0000-0000-0000-000000000003', (now() at time zone 'Asia/Hebron')::date, 1, 'notified');

-- Another buyer cannot record a payment for somebody else's booking.
select pg_temp.as_user('c1000000-0000-0000-0000-000000000003');
select pg_temp.must_fail($$select public.record_wallet_payment('c3000000-0000-0000-0000-000000000001')$$, 'purchase not found');
-- Nobody signed in cannot either.
select pg_temp.as_user(null);
select pg_temp.must_fail($$select public.record_wallet_payment('c3000000-0000-0000-0000-000000000001')$$, 'not authenticated');

-- The owner is not the buyer.
select pg_temp.as_user('c1000000-0000-0000-0000-000000000001');
select pg_temp.must_fail($$select public.record_wallet_payment('c3000000-0000-0000-0000-000000000001')$$, 'purchase not found');

-- The buyer pays through the wallet: one row, the bakery's price, flagged simulated.
select pg_temp.as_user('c1000000-0000-0000-0000-000000000002');
select public.record_wallet_payment('c3000000-0000-0000-0000-000000000001');
-- ...and doing it twice changes nothing.
select public.record_wallet_payment('c3000000-0000-0000-0000-000000000001');
reset role;
do $$ begin
  perform pg_temp.ok((select count(*) = 1 from public.payments where store_id = 'c2000000-0000-0000-0000-000000000001'), 'one payment');
  perform pg_temp.ok((select amount = 4.50 and method = 'jawwal_pay' and provider = 'simulated'
    from public.payments where purchase_id = 'c3000000-0000-0000-0000-000000000001'), 'row shape');
end $$;

-- Collecting a prepaid bag takes no cash: the wallet payment stays the only row.
select pg_temp.as_user('c1000000-0000-0000-0000-000000000001');
select public.collect_purchase('c3000000-0000-0000-0000-000000000001');
-- The unpaid bag is paid in cash when collected.
select public.collect_purchase('c3000000-0000-0000-0000-000000000002');
reset role;
do $$ begin
  perform pg_temp.ok((select method = 'jawwal_pay' from public.payments where purchase_id = 'c3000000-0000-0000-0000-000000000001'), 'prepaid stays wallet');
  perform pg_temp.ok((select method = 'cash' and provider is null from public.payments where purchase_id = 'c3000000-0000-0000-0000-000000000002'), 'unpaid becomes cash');
end $$;

-- A collected bag can no longer be paid for.
select pg_temp.as_user('c1000000-0000-0000-0000-000000000003');
select pg_temp.must_fail($$select public.record_wallet_payment('c3000000-0000-0000-0000-000000000002')$$, 'already collected');

-- "Cash taken" counts the cash bag only.
select pg_temp.as_user('c1000000-0000-0000-0000-000000000001');
do $$
declare r record;
begin
  select * into r from public.store_daily_summaries('c2000000-0000-0000-0000-000000000001', 5) limit 1;
  perform pg_temp.ok(r.sold = 2 and r.collected = 2 and r.cash_total = 4.50, 'cash total is cash only');
end $$;

-- Only the function path writes; the client never inserts a payment.
select pg_temp.must_fail($$insert into public.payments (purchase_id, store_id, user_id, amount, method)
  values ('c3000000-0000-0000-0000-000000000001', 'c2000000-0000-0000-0000-000000000001',
          'c1000000-0000-0000-0000-000000000002', 0, 'jawwal_pay')$$, 'permission denied');
select pg_temp.as_user(null, 'anon');
select pg_temp.must_fail($$select public.record_wallet_payment('c3000000-0000-0000-0000-000000000001')$$, 'permission denied');

reset role;
rollback;
