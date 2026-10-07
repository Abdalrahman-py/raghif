-- Asserts 20261007210000_harden_reserve_stores_and_pin_login.sql:
--   reserve_bag: server-bounded dates, idempotent retry, one bag per day
--   stores:      no direct writes for anyone, owners included
--   PIN login:   lockout after 5 misses, reset on success, 4-digit PINs only
-- Runs after the other SQL tests against the same database, so every id and
-- phone here is distinct from theirs.

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

create function pg_temp.gaza_today() returns date
  language sql as $$ select (now() at time zone 'Asia/Gaza')::date $$;

-- Fixtures (superuser): one owner, two buyers, two stores.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000a1'), -- owner
  ('00000000-0000-0000-0000-0000000000a2'), -- buyer
  ('00000000-0000-0000-0000-0000000000a3'); -- second buyer
insert into public.profiles (id, phone, national_id, pin_hash, name, role) values
  ('00000000-0000-0000-0000-0000000000a1', 'r1', 'r1', 'x', 'owner', 'owner'),
  ('00000000-0000-0000-0000-0000000000a2', 'r2', 'r2', 'x', 'buyer', 'buyer'),
  ('00000000-0000-0000-0000-0000000000a3', 'r3', 'r3', 'x', 'buyer2', 'buyer');
insert into public.stores (id, name, owner_id, is_open, daily_bag_limit, bags_remaining, batch_size) values
  ('20000000-0000-0000-0000-000000000001', 'rs1', '00000000-0000-0000-0000-0000000000a1', true, 3, 3, 2),
  ('20000000-0000-0000-0000-000000000002', 'rs2', '00000000-0000-0000-0000-0000000000a1', true, 3, 3, 2);

-- ------------------------------------------------------------ reserve_bag --
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a2');

-- Dates outside [today, tomorrow] in Gaza are refused, whatever the phone says.
select pg_temp.must_fail(
  format($$select public.reserve_bag('20000000-0000-0000-0000-000000000001', %L)$$,
         pg_temp.gaza_today() - 1), 'invalid purchase date');
select pg_temp.must_fail(
  format($$select public.reserve_bag('20000000-0000-0000-0000-000000000001', %L)$$,
         pg_temp.gaza_today() + 2), 'invalid purchase date');
select pg_temp.must_fail(
  $$select public.reserve_bag('20000000-0000-0000-0000-000000000001', null)$$,
  'invalid purchase date');

-- Idempotent: the retry returns the same purchase and takes no second bag.
do $$
declare a public.purchases; b public.purchases; left_ int;
begin
  a := public.reserve_bag('20000000-0000-0000-0000-000000000001', pg_temp.gaza_today());
  b := public.reserve_bag('20000000-0000-0000-0000-000000000001', pg_temp.gaza_today());
  if a.id is distinct from b.id then
    raise exception 'retry created a second purchase: % vs %', a.id, b.id;
  end if;
  select bags_remaining into left_ from public.stores
   where id = '20000000-0000-0000-0000-000000000001';
  if left_ <> 2 then raise exception 'expected 2 bags left, got %', left_; end if;
end $$;

-- One bag per ID per day across stores.
select pg_temp.must_fail(
  format($$select public.reserve_bag('20000000-0000-0000-0000-000000000002', %L)$$,
         pg_temp.gaza_today()), 'already reserved a bag today');

-- Tomorrow is allowed (pre-order), and is a separate day.
select public.reserve_bag('20000000-0000-0000-0000-000000000002', pg_temp.gaza_today() + 1);

-- ----------------------------------------------------------------- stores --
select pg_temp.as_user('00000000-0000-0000-0000-0000000000a1');
select pg_temp.must_fail(
  $$update public.stores set bags_remaining = 999
     where id = '20000000-0000-0000-0000-000000000001'$$, 'permission denied');
select pg_temp.must_fail(
  $$delete from public.stores where id = '20000000-0000-0000-0000-000000000001'$$,
  'permission denied');
select pg_temp.must_fail(
  $$insert into public.stores (name, owner_id)
    values ('mine now', '00000000-0000-0000-0000-0000000000a1')$$, 'permission denied');
-- The RPC path still works for the owner.
select public.save_store_allocation('20000000-0000-0000-0000-000000000001', 4, 2, pg_temp.gaza_today());
reset role;

-- ------------------------------------------------------------- PIN login --
select pg_temp.must_fail(
  $$select public.create_profile(gen_random_uuid(), 'p0', 'p0', 'abcd', 'bad', null)$$,
  'PIN must be exactly 4 digits');
select pg_temp.must_fail(
  $$select public.create_profile(gen_random_uuid(), 'p0', 'p0', '12345', 'bad', null)$$,
  'PIN must be exactly 4 digits');

insert into auth.users (id) values ('00000000-0000-0000-0000-0000000000b1');
select pg_temp.as_user(null, 'service_role');
select public.create_profile('00000000-0000-0000-0000-0000000000b1', 'p1', 'p1', '1234', 'pin user', null);

do $$
declare r public.profiles; i int;
begin
  -- Wrong PINs answer null, and the fifth locks the account.
  for i in 1..5 loop
    r := public.verify_pin_and_get_profile('p1', 'national_id', '0000');
    if r.id is not null then raise exception 'wrong PIN was accepted'; end if;
  end loop;

  -- Locked: even the right PIN is refused.
  r := public.verify_pin_and_get_profile('p1', 'national_id', '1234');
  if r.id is not null then raise exception 'locked account accepted the right PIN'; end if;
end $$;

-- Time passes (superuser edits the clock-bearing column).
reset role;
update public.profiles set pin_locked_until = now() - interval '1 minute'
 where national_id = 'p1';
select pg_temp.as_user(null, 'service_role');

do $$
declare r public.profiles;
begin
  r := public.verify_pin_and_get_profile('p1', 'national_id', '1234');
  if r.id is null then raise exception 'right PIN refused after the lockout expired'; end if;
  if r.failed_pin_attempts <> 0 or r.pin_locked_until is not null then
    raise exception 'counters not reset after a successful login';
  end if;
  -- An unknown identifier is just null, same as a wrong PIN.
  if public.verify_pin_and_get_profile('nobody', 'national_id', '1234') is not null then
    raise exception 'unknown identifier returned a profile';
  end if;
end $$;
reset role;

-- The app can neither read nor reset the lockout counters.
select pg_temp.as_user('00000000-0000-0000-0000-0000000000b1');
select pg_temp.must_fail('select failed_pin_attempts from public.profiles', 'permission denied');
select pg_temp.must_fail(
  $$update public.profiles set failed_pin_attempts = 0
     where id = '00000000-0000-0000-0000-0000000000b1'$$, 'permission denied');
reset role;
