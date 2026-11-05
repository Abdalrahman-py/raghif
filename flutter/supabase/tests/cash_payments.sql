-- Rollback-only checks for 20261105100000_cash_payments.
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

-- Fixtures: two owners, two buyers, one store each; the buyer holds a notified
-- bag today at store 1 (price 4.50).
insert into auth.users (id) values
  ('d0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000002'),
  ('d0000000-0000-0000-0000-000000000003'),
  ('d0000000-0000-0000-0000-000000000004');
insert into public.profiles (id, phone, national_id, pin_hash, name, role) values
  ('d0000000-0000-0000-0000-000000000001', 'cp-1', 'cp-n1', 'x', 'cp-owner1', 'owner'),
  ('d0000000-0000-0000-0000-000000000002', 'cp-2', 'cp-n2', 'x', 'cp-owner2', 'owner'),
  ('d0000000-0000-0000-0000-000000000003', 'cp-3', 'cp-n3', 'x', 'cp-buyer1', 'buyer'),
  ('d0000000-0000-0000-0000-000000000004', 'cp-4', 'cp-n4', 'x', 'cp-buyer2', 'buyer');
insert into public.stores (id, name, owner_id, is_open, daily_bag_limit, bags_remaining, batch_size, bag_price) values
  ('e0000000-0000-0000-0000-000000000001', 'cp-store1', 'd0000000-0000-0000-0000-000000000001', true, 5, 5, 2, 4.50),
  ('e0000000-0000-0000-0000-000000000002', 'cp-store2', 'd0000000-0000-0000-0000-000000000002', true, 5, 5, 2, 3.00);
insert into public.purchases (id, store_id, user_id, purchase_date, batch_number, status) values
  ('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001',
   'd0000000-0000-0000-0000-000000000003', (now() at time zone 'Asia/Hebron')::date, 1, 'notified'),
  ('f0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001',
   'd0000000-0000-0000-0000-000000000004', (now() at time zone 'Asia/Hebron')::date, 1, 'waiting');

-- Nothing is paid before it is collected.
do $$ begin
  perform pg_temp.ok((select count(*) = 0 from public.payments where store_id::text like 'e0000000%'), 'no payment before collection');
end $$;

-- Another bakery's owner cannot collect it, and a waiting bag cannot be collected.
select pg_temp.as_user('d0000000-0000-0000-0000-000000000002');
select pg_temp.must_fail($$select public.collect_purchase('f0000000-0000-0000-0000-000000000001')$$, 'not the store owner');
select pg_temp.as_user('d0000000-0000-0000-0000-000000000001');
select pg_temp.must_fail($$select public.collect_purchase('f0000000-0000-0000-0000-000000000002')$$, 'batch not notified');

-- The owner collects: one cash payment at the store's price.
select public.collect_purchase('f0000000-0000-0000-0000-000000000001');
-- ...and collecting again does not pay twice.
select public.collect_purchase('f0000000-0000-0000-0000-000000000001');
reset role;
do $$ begin
  perform pg_temp.ok((select count(*) = 1 from public.payments where store_id::text like 'e0000000%'), 'one payment');
  perform pg_temp.ok((select amount = 4.50 and method = 'cash' and status = 'paid'
    and user_id = 'd0000000-0000-0000-0000-000000000003'
    and store_id = 'e0000000-0000-0000-0000-000000000001' from public.payments where store_id::text like 'e0000000%'), 'payment row');
end $$;

-- The price on the row is the price at collection, not a live reference.
update public.stores set bag_price = 9 where id = 'e0000000-0000-0000-0000-000000000001';
do $$ begin
  perform pg_temp.ok((select amount = 4.50 from public.payments where store_id::text like 'e0000000%'), 'amount frozen');
end $$;

-- Visibility: the buyer and the bakery's owner see it; nobody else does.
select pg_temp.as_user('d0000000-0000-0000-0000-000000000003');
do $$ begin
  perform pg_temp.ok((select count(*) = 1 from public.payments where store_id::text like 'e0000000%'), 'buyer sees own');
end $$;
select pg_temp.as_user('d0000000-0000-0000-0000-000000000004');
do $$ begin
  perform pg_temp.ok((select count(*) = 0 from public.payments where store_id::text like 'e0000000%'), 'other buyer sees none');
end $$;
select pg_temp.as_user('d0000000-0000-0000-0000-000000000002');
do $$ begin
  perform pg_temp.ok((select count(*) = 0 from public.payments where store_id::text like 'e0000000%'), 'other owner sees none');
end $$;
select pg_temp.as_user('d0000000-0000-0000-0000-000000000001');
do $$ begin
  perform pg_temp.ok((select count(*) = 1 from public.payments where store_id::text like 'e0000000%'), 'owner sees own bakery');
end $$;

-- The client cannot write payments at all.
select pg_temp.must_fail($$insert into public.payments (purchase_id, store_id, user_id, amount)
  values ('f0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001',
          'd0000000-0000-0000-0000-000000000004', 1)$$, 'permission denied');
select pg_temp.must_fail($$update public.payments set amount = 0$$, 'permission denied');
select pg_temp.must_fail($$delete from public.payments$$, 'permission denied');

-- The owner's day summary carries the cash.
do $$
declare r record;
begin
  select * into r from public.store_daily_summaries('e0000000-0000-0000-0000-000000000001', 5) limit 1;
  perform pg_temp.ok(r.sold = 2 and r.collected = 1 and r.not_collected = 1 and r.cash_total = 4.50, 'summary cash');
end $$;
select pg_temp.as_user('d0000000-0000-0000-0000-000000000002');
select pg_temp.must_fail($$select * from public.store_daily_summaries('e0000000-0000-0000-0000-000000000001', 5)$$, 'not the store owner');

reset role;
rollback;
