-- Asserts the guarantees of 20260930090000_lock_direct_writes.sql.
-- Each check runs as a real role with a JWT subject, like PostgREST would.

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

-- Fixtures, written as the superuser: an owner, two buyers, two stores.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'), -- owner
  ('00000000-0000-0000-0000-00000000000b'), -- buyer 1
  ('00000000-0000-0000-0000-00000000000c'), -- buyer 2
  ('00000000-0000-0000-0000-00000000000d'); -- other owner
insert into public.profiles (id, phone, national_id, pin_hash, name, role) values
  ('00000000-0000-0000-0000-00000000000a', '1', '1', 'secret-hash-a', 'owner', 'owner'),
  ('00000000-0000-0000-0000-00000000000b', '2', '2', 'secret-hash-b', 'buyer1', 'buyer'),
  ('00000000-0000-0000-0000-00000000000c', '3', '3', 'secret-hash-c', 'buyer2', 'buyer'),
  ('00000000-0000-0000-0000-00000000000d', '4', '4', 'secret-hash-d', 'owner2', 'owner');
insert into public.stores (id, name, owner_id, is_open, daily_bag_limit, bags_remaining, batch_size) values
  ('10000000-0000-0000-0000-000000000001', 'mine',  '00000000-0000-0000-0000-00000000000a', true, 5, 5, 2),
  ('10000000-0000-0000-0000-000000000002', 'other', '00000000-0000-0000-0000-00000000000d', true, 5, 5, 2);

-- Buyers reserve through the RPC: the only way in.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select public.reserve_bag('10000000-0000-0000-0000-000000000001', current_date);
select pg_temp.as_user('00000000-0000-0000-0000-00000000000c');
select public.reserve_bag('10000000-0000-0000-0000-000000000002', current_date);

-- profiles: the owner reads buyers' rows, never their pin_hash or a raw *.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select pg_temp.must_fail('select * from public.profiles', 'permission denied');
select pg_temp.must_fail('select pin_hash from public.profiles', 'permission denied');
select id, name, role from public.profiles;
select pg_temp.must_fail(
  $$update public.profiles set role = 'owner' where id = '00000000-0000-0000-0000-00000000000a'$$,
  'permission denied');
select pg_temp.must_fail(
  $$update public.profiles set pin_hash = 'x' where id = '00000000-0000-0000-0000-00000000000a'$$,
  'permission denied');
update public.profiles set name = 'owner renamed'
 where id = '00000000-0000-0000-0000-00000000000a';

-- purchases: no direct writes, even for the store owner.
do $$ declare n int; begin
  update public.purchases set status = 'collected'; get diagnostics n = row_count;
  if n <> 0 then raise exception 'owner updated % purchase rows directly', n; end if;
end $$;
select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select pg_temp.must_fail(
  $$insert into public.purchases (store_id, user_id, purchase_date, batch_number)
    values ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b',
            current_date + 1, 1)$$,
  'row-level security');

-- collect_purchase: a waiting batch is refused, a notified one is collected,
-- a repeat is harmless, and another store's owner is turned away.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
create temp table t_purchase as
  select id from public.purchases where store_id = '10000000-0000-0000-0000-000000000001';
grant select on t_purchase to authenticated;
select pg_temp.must_fail(
  $$select public.collect_purchase((select id from t_purchase))$$, 'not notified');
select public.notify_next_batch('10000000-0000-0000-0000-000000000001', current_date);
select public.collect_purchase((select id from t_purchase));
do $$ begin
  if (select status from public.collect_purchase((select id from t_purchase))) <> 'collected'
  then raise exception 'repeat collect should be idempotent'; end if;
end $$;
select pg_temp.as_user('00000000-0000-0000-0000-00000000000d');
select pg_temp.must_fail(
  $$select public.collect_purchase((select id from t_purchase))$$, 'not the store owner');

-- record_scan: unknown outcome refused; a foreign purchase is not linked.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select pg_temp.must_fail(
  $$select public.record_scan('10000000-0000-0000-0000-000000000001', 'bogus')$$,
  'unknown scan outcome');
do $$
declare v_other uuid; v_event public.scan_events;
begin
  select id into v_other from public.purchases
   where store_id = '10000000-0000-0000-0000-000000000002';
  -- The owner cannot see the other store's purchase through RLS, so read it
  -- back as the other store's owner first.
  perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000d', false);
  select id into v_other from public.purchases
   where store_id = '10000000-0000-0000-0000-000000000002';
  perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', false);
  v_event := public.record_scan('10000000-0000-0000-0000-000000000001', 'wrongStore', v_other);
  if v_event.purchase_id is not null then
    raise exception 'scan must not link another store''s purchase';
  end if;
  v_event := public.record_scan('10000000-0000-0000-0000-000000000001', 'checkedIn',
                                (select id from t_purchase));
  if v_event.purchase_id is null then raise exception 'own purchase should link'; end if;
end $$;
select pg_temp.must_fail(
  $$insert into public.scan_events (store_id, outcome)
    values ('10000000-0000-0000-0000-000000000001', 'checkedIn')$$,
  'row-level security');

-- save_store_allocation: recomputes remaining from what was sold, leaves
-- is_open alone, and only the owner may call it.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select public.set_store_open('10000000-0000-0000-0000-000000000001', false);
do $$
declare v public.stores;
begin
  v := public.save_store_allocation('10000000-0000-0000-0000-000000000001', 10, 3, current_date, '08:00', '10:00');
  if v.bags_remaining <> 9 then raise exception 'remaining should be 10 - 1 sold, got %', v.bags_remaining; end if;
  if v.is_open then raise exception 'allocation must not reopen a closed store'; end if;
  if v.batch_size <> 3 then raise exception 'batch size not saved'; end if;
end $$;
select pg_temp.as_user('00000000-0000-0000-0000-00000000000d');
select pg_temp.must_fail(
  $$select public.save_store_allocation('10000000-0000-0000-0000-000000000001', 10, 3, current_date)$$,
  'not the store owner');

-- anon may not call any owner RPC.
select pg_temp.as_user(null, 'anon');
select pg_temp.must_fail(
  $$select public.collect_purchase('00000000-0000-0000-0000-000000000000')$$, 'permission denied');
select pg_temp.must_fail(
  $$select public.store_customers('10000000-0000-0000-0000-000000000001')$$, 'permission denied');
select pg_temp.must_fail(
  $$select public.record_scan('10000000-0000-0000-0000-000000000001', 'checkedIn')$$, 'permission denied');
