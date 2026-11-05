-- Standalone, rollback-only checks for the admin panel migrations
-- (20261104100000 .. 20261104103000). Each step runs as a real role with a JWT
-- subject, like PostgREST would.
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

-- Fixtures (superuser): an admin, two owners, three buyers, three stores.
insert into auth.users (id) values
  ('a0000000-0000-0000-0000-000000000001'), -- admin
  ('a0000000-0000-0000-0000-000000000002'), -- owner 1
  ('a0000000-0000-0000-0000-000000000003'), -- owner 2
  ('a0000000-0000-0000-0000-000000000004'), -- buyer 1
  ('a0000000-0000-0000-0000-000000000005'), -- buyer 2
  ('a0000000-0000-0000-0000-000000000006'); -- buyer 3
insert into public.profiles (id, phone, national_id, pin_hash, name, role) values
  ('a0000000-0000-0000-0000-000000000001', 'tst-7001', 'tst-n7001', 'x', 'tst-admin',  'buyer'),
  ('a0000000-0000-0000-0000-000000000002', 'tst-7002', 'tst-n7002',
     extensions.crypt('4829', extensions.gen_salt('bf')), 'tst-owner1', 'owner'),
  ('a0000000-0000-0000-0000-000000000003', 'tst-7003', 'tst-n7003', 'x', 'tst-owner2', 'owner'),
  ('a0000000-0000-0000-0000-000000000004', 'tst-7004', 'tst-n7004', 'x', 'tst-buyer1', 'buyer'),
  ('a0000000-0000-0000-0000-000000000005', 'tst-7005', 'tst-n7005', 'x', 'tst-buyer2', 'buyer'),
  ('a0000000-0000-0000-0000-000000000006', 'tst-7006', 'tst-n7006', 'x', 'tst-buyer3', 'buyer');
insert into public.admins (user_id) values ('a0000000-0000-0000-0000-000000000001');
insert into public.stores (id, name, owner_id, is_open, daily_bag_limit, bags_remaining, batch_size) values
  ('b0000000-0000-0000-0000-000000000001', 'tst-store1', 'a0000000-0000-0000-0000-000000000002', true, 5, 5, 2),
  ('b0000000-0000-0000-0000-000000000002', 'tst-store2', 'a0000000-0000-0000-0000-000000000003', true, 5, 5, 2),
  ('b0000000-0000-0000-0000-000000000003', 'tst-store3', null,                                  true, 5, 5, 2);

-- Defaults: price 3, status active.
do $$ begin
  perform pg_temp.ok((select bag_price = 3 and status = 'active'
    from public.stores where id = 'b0000000-0000-0000-0000-000000000001'), 'store defaults');
  perform pg_temp.ok((select account_status = 'active'
    from public.profiles where id = 'a0000000-0000-0000-0000-000000000004'), 'profile default');
end $$;

-- ------------------------------------------------------------ admin gate --

-- A buyer and an owner are refused; so is anon (no execute at all).
select pg_temp.as_user('a0000000-0000-0000-0000-000000000004');
select pg_temp.must_fail('select public.admin_overview()', 'not authorized');
select pg_temp.must_fail('select * from public.admin_list_buyers()', 'not authorized');
select pg_temp.must_fail($$select public.admin_set_store_status('b0000000-0000-0000-0000-000000000001', 'paused')$$, 'not authorized');
select pg_temp.must_fail($$select public.admin_send_notification('all', 't', 'b')$$, 'not authorized');
select pg_temp.must_fail('select * from public.admins', 'permission denied');
reset role;
select pg_temp.as_user('a0000000-0000-0000-0000-000000000002');
select pg_temp.must_fail('select public.admin_overview()', 'not authorized');
reset role;
select pg_temp.as_user(null, 'anon');
select pg_temp.must_fail('select public.admin_overview()', 'permission denied');
select pg_temp.must_fail('select public.is_admin()', 'permission denied');
reset role;
-- service-only helpers are closed to signed-in users.
select pg_temp.as_user('a0000000-0000-0000-0000-000000000001');
select pg_temp.must_fail($$select public.account_login_block('a0000000-0000-0000-0000-000000000004')$$, 'permission denied');
select pg_temp.must_fail($$select public.admin_create_store_for('a0000000-0000-0000-0000-000000000002', 'x', 'a', 'غزة')$$, 'permission denied');
reset role;

-- ------------------------------------------------------- owner guardrails --

select pg_temp.as_user('a0000000-0000-0000-0000-000000000002');
-- The owner's everyday toggle still works.
update public.stores set is_open = false where id = 'b0000000-0000-0000-0000-000000000001';
update public.stores set is_open = true  where id = 'b0000000-0000-0000-0000-000000000001';
-- But not the columns only the administrator controls.
select pg_temp.must_fail($$update public.stores set status = 'paused' where id = 'b0000000-0000-0000-0000-000000000001'$$, 'managed by the administrator');
select pg_temp.must_fail($$update public.stores set bag_price = 1 where id = 'b0000000-0000-0000-0000-000000000001'$$, 'managed by the administrator');
-- No hard delete of a store or a profile.
select pg_temp.must_fail($$delete from public.stores where id = 'b0000000-0000-0000-0000-000000000001'$$, 'permission denied');
select pg_temp.must_fail($$delete from public.profiles where id = 'a0000000-0000-0000-0000-000000000002'$$, 'permission denied');
-- A store the owner inserts is forced to the defaults.
insert into public.stores (name, owner_id, is_open, daily_bag_limit, bags_remaining, batch_size, bag_price, status)
  values ('self-made', 'a0000000-0000-0000-0000-000000000002', true, 5, 5, 2, 99, 'paused');
reset role;
do $$ begin
  perform pg_temp.ok((select bag_price = 3 and status = 'active'
    from public.stores where name = 'self-made'), 'insert forced to defaults');
end $$;
delete from public.stores where name = 'self-made';

-- --------------------------------------------------- admin reads and edits --

select pg_temp.as_user('a0000000-0000-0000-0000-000000000001');
do $$ declare o jsonb; begin
  o := public.admin_overview();
  perform pg_temp.ok((o->>'stores_total')::int >= 3, 'overview stores_total');
  perform pg_temp.ok((o->>'stores_active')::int >= 3, 'overview stores_active');
  perform pg_temp.ok((o->>'buyers_total')::int >= 4, 'overview buyers_total');
  perform pg_temp.ok((o->>'owners_total')::int >= 2, 'overview owners_total');
  perform pg_temp.ok(o ? 'revenue_estimate_total', 'overview revenue key');
end $$;
do $$ begin
  perform pg_temp.ok((select count(*) = 30 from public.admin_daily_series(30)), 'series is zero-filled');
  perform pg_temp.ok((select min(day) < max(day) from public.admin_daily_series(30)), 'series ordered');
  perform pg_temp.ok((select count(*) = 366 from public.admin_daily_series(9999)), 'series capped at 366');
end $$;
do $$ begin
  perform pg_temp.ok((select count(*) = 1 from public.admin_list_buyers('tst-buyer2')), 'buyer search by name: ' || (select count(*) from public.admin_list_buyers('tst-buyer2')));
  perform pg_temp.ok((select count(*) = 1 from public.admin_list_buyers('tst-7006')), 'buyer search by phone');
  perform pg_temp.ok((select count(*) = 1 from public.admin_list_buyers('tst-7004', 1, 0)), 'buyer search limit');
  perform pg_temp.ok((select bool_and(role_ok) from (
    select true as role_ok from public.admin_list_buyers() where name in ('tst-owner1', 'tst-owner2')
  ) x) is null, 'owners are not listed as buyers');
  perform pg_temp.ok((select idle from public.admin_list_stores() where name = 'tst-store1'), 'store with no bookings is idle');
  perform pg_temp.ok((select owner_name = 'tst-owner1' from public.admin_list_stores() where name = 'tst-store1'), 'store owner joined');
end $$;

-- Editing a store: stock is recomputed, price and status change.
select public.admin_update_store('b0000000-0000-0000-0000-000000000001', p_daily_bag_limit => 8, p_bag_price => 4.5);
do $$ begin
  perform pg_temp.ok((select daily_bag_limit = 8 and bags_remaining = 8 and bag_price = 4.5
    from public.admin_list_stores() where name = 'tst-store1'), 'update store');
end $$;
select pg_temp.must_fail($$select public.admin_update_store('b0000000-0000-0000-0000-000000000001', p_bag_price => -1)$$, 'price cannot be negative');
select pg_temp.must_fail($$select public.admin_update_store('b0000000-0000-0000-0000-000000000099', p_name => 'x')$$, 'store not found');
select pg_temp.must_fail($$select public.admin_set_store_status('b0000000-0000-0000-0000-000000000001', 'deleted')$$, 'invalid status');
select pg_temp.must_fail($$select public.admin_set_buyer_status('a0000000-0000-0000-0000-000000000001', 'disabled')$$, 'administrator cannot be disabled');
select pg_temp.must_fail($$select public.admin_set_verification('a0000000-0000-0000-0000-000000000004', 'rejected')$$, 'invalid status');
select public.admin_set_verification('a0000000-0000-0000-0000-000000000004', 'verified');
do $$ begin
  perform pg_temp.ok(not (public.admin_set_verification('a0000000-0000-0000-0000-000000000004', 'verified') ? 'pin_hash'), 'no PIN hash returned');
  perform pg_temp.ok(not (public.admin_set_buyer_status('a0000000-0000-0000-0000-000000000005', 'active') ? 'pin_hash'), 'no PIN hash returned (status)');
end $$;
reset role;
do $$ begin
  perform pg_temp.ok((select verification_status = 'verified' from public.profiles
    where id = 'a0000000-0000-0000-0000-000000000004'), 'verification set');
end $$;

-- A limit below tomorrow's bookings is refused (same rule as the owner's save).
insert into public.purchases (store_id, user_id, purchase_date, batch_number, status)
  select 'b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000005',
         (now() at time zone 'Asia/Hebron')::date + 1, 1, 'waiting';
select pg_temp.as_user('a0000000-0000-0000-0000-000000000001');
select pg_temp.must_fail($$select public.admin_update_store('b0000000-0000-0000-0000-000000000001', p_daily_bag_limit => 0)$$, 'below existing future bookings');
reset role;

-- --------------------------------------------------------- store statuses --

-- Paused: still listed, but nobody can book.
select pg_temp.as_user('a0000000-0000-0000-0000-000000000001');
select public.admin_set_store_status('b0000000-0000-0000-0000-000000000002', 'paused');
reset role;
select pg_temp.as_user('a0000000-0000-0000-0000-000000000004');
select pg_temp.must_fail($$select public.reserve_bag('b0000000-0000-0000-0000-000000000002', (now() at time zone 'Asia/Hebron')::date)$$, 'store closed or sold out');
do $$ begin
  perform pg_temp.ok((select count(*) = 1 from public.stores where id = 'b0000000-0000-0000-0000-000000000002'),
    'paused store is still visible');
end $$;
reset role;

-- Active: booking works (also proves the rewritten reserve_bag still reserves).
select pg_temp.as_user('a0000000-0000-0000-0000-000000000004');
select public.reserve_bag('b0000000-0000-0000-0000-000000000001', (now() at time zone 'Asia/Hebron')::date);
reset role;
do $$ begin
  perform pg_temp.ok((select bags_remaining = 7 from public.stores
    where id = 'b0000000-0000-0000-0000-000000000001'), 'reserve_bag decremented stock');
end $$;

-- Archived: hidden from anon and from buyers with no booking there; visible
-- to its owner and to a buyer who already booked.
select pg_temp.as_user('a0000000-0000-0000-0000-000000000001');
select public.admin_set_store_status('b0000000-0000-0000-0000-000000000001', 'archived');
reset role;
select pg_temp.as_user(null, 'anon');
do $$ begin
  perform pg_temp.ok((select count(*) = 0 from public.stores where id = 'b0000000-0000-0000-0000-000000000001'),
    'archived hidden from anon');
  perform pg_temp.ok((select count(*) = 1 from public.stores where id = 'b0000000-0000-0000-0000-000000000003'),
    'active store visible to anon');
end $$;
reset role;
select pg_temp.as_user('a0000000-0000-0000-0000-000000000006'); -- booked nowhere
do $$ begin
  perform pg_temp.ok((select count(*) = 0 from public.stores where id = 'b0000000-0000-0000-0000-000000000001'),
    'archived hidden from a buyer with no booking');
end $$;
reset role;
select pg_temp.as_user('a0000000-0000-0000-0000-000000000004'); -- booked there today
do $$ begin
  perform pg_temp.ok((select count(*) = 1 from public.stores where id = 'b0000000-0000-0000-0000-000000000001'),
    'archived still visible to a buyer with a booking');
end $$;
select pg_temp.must_fail($$select public.reserve_bag('b0000000-0000-0000-0000-000000000001', (now() at time zone 'Asia/Hebron')::date)$$, 'store closed or sold out');
reset role;
select pg_temp.as_user('a0000000-0000-0000-0000-000000000002');
do $$ begin
  perform pg_temp.ok((select count(*) = 1 from public.stores where id = 'b0000000-0000-0000-0000-000000000001'),
    'archived visible to its owner');
end $$;
reset role;

-- Disabled buyer cannot book.
select pg_temp.as_user('a0000000-0000-0000-0000-000000000001');
select public.admin_set_buyer_status('a0000000-0000-0000-0000-000000000006', 'disabled');
reset role;
select pg_temp.as_user('a0000000-0000-0000-0000-000000000006');
select pg_temp.must_fail($$select public.reserve_bag('b0000000-0000-0000-0000-000000000003', (now() at time zone 'Asia/Hebron')::date)$$, 'account disabled');
reset role;

-- ------------------------------------------------------------- login gate --

do $$ begin
  perform pg_temp.ok(public.account_login_block('a0000000-0000-0000-0000-000000000006') = 'account_disabled', 'disabled account blocked');
  perform pg_temp.ok(public.account_login_block('a0000000-0000-0000-0000-000000000002') = 'store_archived', 'archived-store owner blocked');
  perform pg_temp.ok(public.account_login_block('a0000000-0000-0000-0000-000000000003') is null, 'paused-store owner may sign in');
  perform pg_temp.ok(public.account_login_block('a0000000-0000-0000-0000-000000000005') is null, 'normal buyer may sign in');
end $$;

-- ----------------------------------------------------------- announcements --

select pg_temp.as_user('a0000000-0000-0000-0000-000000000001');
select pg_temp.must_fail($$select public.admin_send_notification('everyone', 't', 'b')$$, 'invalid target');
select pg_temp.must_fail($$select public.admin_send_notification('all', '', 'b')$$, 'invalid title');
select pg_temp.must_fail($$select public.admin_send_notification('all', 't', '')$$, 'invalid body');
select pg_temp.must_fail($$select public.admin_send_notification('store', 't', 'b', 'b0000000-0000-0000-0000-000000000003')$$, 'store not found');
do $$ declare n int; begin
  -- store 2's owner only
  n := public.admin_send_notification('store', 'مرحبا', 'رسالة', 'b0000000-0000-0000-0000-000000000002');
  perform pg_temp.ok(n = 1, 'store target reaches the owner');
  -- active buyers only: buyer3 is disabled
  n := public.admin_send_notification('buyers', 'عنوان', 'نص');
  perform pg_temp.ok(n >= 3, 'buyers target reaches at least the three fixtures: ' || n);
end $$;
reset role;
do $$ begin
  perform pg_temp.ok((select count(*) = (select count(*) from public.profiles where role = 'buyer' and account_status = 'active')
    from public.notification_inbox where kind = 'announcement' and title = 'عنوان'), 'buyers target reaches exactly the active buyers');
end $$;
do $$ begin
  perform pg_temp.ok((select count(*) = 0 from public.notification_inbox
    where kind = 'announcement' and purchase_id is not null), 'announcements have no purchase');
  perform pg_temp.ok((select count(*) = 0 from public.notification_inbox
    where kind = 'announcement' and user_id = 'a0000000-0000-0000-0000-000000000006'), 'disabled account got nothing');
end $$;
-- A recipient reads their own announcement and nobody else's.
select pg_temp.as_user('a0000000-0000-0000-0000-000000000005');
do $$ begin
  perform pg_temp.ok((select count(*) = 1 from public.notification_inbox where kind = 'announcement'), 'buyer reads own announcement only');
end $$;
reset role;

-- ----------------------------------------------------------- change_my_pin --

update public.profiles set pin_hash = extensions.crypt('4829', extensions.gen_salt('bf'))
 where id = 'a0000000-0000-0000-0000-000000000004';
select pg_temp.as_user('a0000000-0000-0000-0000-000000000004'); -- a buyer
do $$ begin
  -- (buyers may change their own PIN since 20261105120000; the account must
  -- still be active, and the current PIN must be right)
  perform pg_temp.ok(public.change_my_pin('0000', '9137') = 'wrong_pin', 'a buyer is checked like anyone else');
  perform pg_temp.ok(public.change_my_pin('4829', '9137') = 'ok', 'a buyer can change their own PIN');
end $$;
reset role;
select pg_temp.as_user('a0000000-0000-0000-0000-000000000002'); -- owner1, PIN 4829
do $$ begin
  perform pg_temp.ok(public.change_my_pin('4829', 'abcd') = 'invalid_pin', 'non-digit PIN');
  perform pg_temp.ok(public.change_my_pin('4829', '123') = 'invalid_pin', 'short PIN');
  perform pg_temp.ok(public.change_my_pin('4829', '0000') = 'weak_pin', 'repeated digits');
  perform pg_temp.ok(public.change_my_pin('4829', '1234') = 'weak_pin', 'sequence');
  perform pg_temp.ok(public.change_my_pin('4829', '4829') = 'same_pin', 'unchanged PIN');
  perform pg_temp.ok(public.change_my_pin('0001', '9137') = 'wrong_pin', 'wrong current PIN');
  perform pg_temp.ok(public.change_my_pin('4829', '9137') = 'ok', 'change succeeds');
  perform pg_temp.ok(public.change_my_pin('9137', '2580') = 'ok', 'new PIN is the one that works');
end $$;
reset role;
do $$ begin
  perform pg_temp.ok((select pin_failed_attempts = 0 and pin_locked_until is null from public.profiles
    where id = 'a0000000-0000-0000-0000-000000000002'), 'success clears the counter');
end $$;
select pg_temp.as_user('a0000000-0000-0000-0000-000000000002');
do $$ begin
  -- Four wrong tries, the fifth locks, then even the right PIN is refused.
  perform pg_temp.ok(public.change_my_pin('1111', '7351') = 'wrong_pin', 'wrong 1');
  perform pg_temp.ok(public.change_my_pin('1111', '7351') = 'wrong_pin', 'wrong 2');
  perform pg_temp.ok(public.change_my_pin('1111', '7351') = 'wrong_pin', 'wrong 3');
  perform pg_temp.ok(public.change_my_pin('1111', '7351') = 'wrong_pin', 'wrong 4');
  perform pg_temp.ok(public.change_my_pin('1111', '7351') = 'locked', 'fifth wrong locks');
  perform pg_temp.ok(public.change_my_pin('2580', '7351') = 'locked', 'locked even with the right PIN');
end $$;
reset role;
-- After the lock expires the right PIN works again.
update public.profiles set pin_locked_until = now() - interval '1 minute'
 where id = 'a0000000-0000-0000-0000-000000000002';
select pg_temp.as_user('a0000000-0000-0000-0000-000000000002');
do $$ begin
  perform pg_temp.ok(public.change_my_pin('2580', '7351') = 'ok', 'works after the lock expires');
end $$;
select pg_temp.as_user(null, 'anon');
select pg_temp.must_fail($$select public.change_my_pin('1', '2')$$, 'permission denied');
reset role;

-- The PIN hash and counters never reach a signed-in client.
select pg_temp.as_user('a0000000-0000-0000-0000-000000000002');
select pg_temp.must_fail('select pin_hash from public.profiles', 'permission denied');
select pg_temp.must_fail('select pin_failed_attempts from public.profiles', 'permission denied');
select pg_temp.must_fail($$update public.profiles set account_status = 'active' where id = 'a0000000-0000-0000-0000-000000000002'$$, 'permission denied');
reset role;

-- --------------------------------------------------------- service helper --

select pg_temp.as_user(null, 'service_role');
do $$ declare s public.stores; begin
  s := public.admin_create_store_for('a0000000-0000-0000-0000-000000000003', 'dup', 'a', 'غزة');
exception when others then
  if sqlerrm not like '%already has a store%' then raise; end if;
end $$;
reset role;

-- ---------------------------------------------------- service-only helpers --

select pg_temp.as_user('a0000000-0000-0000-0000-000000000001');
select pg_temp.must_fail($$select public.admin_revoke_sessions('a0000000-0000-0000-0000-000000000004')$$, 'permission denied');
select pg_temp.must_fail($$select public.admin_set_pin('a0000000-0000-0000-0000-000000000004', '5921')$$, 'permission denied');
reset role;

insert into auth.sessions (user_id) values
  ('a0000000-0000-0000-0000-000000000004'),
  ('a0000000-0000-0000-0000-000000000004'),
  ('a0000000-0000-0000-0000-000000000005');
select pg_temp.as_user(null, 'service_role');
do $$ begin
  perform pg_temp.ok(public.admin_revoke_sessions('a0000000-0000-0000-0000-000000000004') = 2, 'both sessions revoked');
end $$;
reset role;
do $$ begin
  perform pg_temp.ok((select count(*) = 0 from auth.sessions where user_id = 'a0000000-0000-0000-0000-000000000004'), 'user signed out');
  perform pg_temp.ok((select count(*) = 1 from auth.sessions where user_id = 'a0000000-0000-0000-0000-000000000005'), 'other users untouched');
end $$;

-- admin_set_pin: the new PIN verifies, the old one does not, locks are cleared.
update public.profiles set pin_failed_attempts = 4, pin_locked_until = now() + interval '10 minutes'
 where id = 'a0000000-0000-0000-0000-000000000003';
select pg_temp.as_user(null, 'service_role');
select public.admin_set_pin('a0000000-0000-0000-0000-000000000003', '5921');
select pg_temp.must_fail($$select public.admin_set_pin('a0000000-0000-0000-0000-000000000003', '59')$$, 'invalid pin');
select pg_temp.must_fail($$select public.admin_set_pin('a0000000-0000-0000-0000-000000000099', '5921')$$, 'user not found');
select pg_temp.must_fail($$select public.admin_set_pin('a0000000-0000-0000-0000-000000000001', '5921')$$, 'administrator');
reset role;
do $$ begin
  perform pg_temp.ok((select id from public.verify_pin_and_get_profile('tst-7003', 'phone', '5921')) = 'a0000000-0000-0000-0000-000000000003', 'new PIN logs in');
  perform pg_temp.ok((select id from public.verify_pin_and_get_profile('tst-7003', 'phone', '4829')) is null, 'old PIN no longer works');
  perform pg_temp.ok((select pin_failed_attempts = 0 and pin_locked_until is null from public.profiles
    where id = 'a0000000-0000-0000-0000-000000000003'), 'lock cleared by reset');
end $$;

rollback;
