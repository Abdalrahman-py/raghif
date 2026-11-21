-- Rollback-only checks for 20261121120000_publish_hardening.
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
  ('ab000000-0000-0000-0000-000000000001'),
  ('ab000000-0000-0000-0000-000000000002');
insert into public.profiles (id, phone, pin_hash, name, role) values
  ('ab000000-0000-0000-0000-000000000001', 'ph-1', 'x', 'ph-owner', 'owner'),
  ('ab000000-0000-0000-0000-000000000002', 'ph-2', 'x', 'ph-buyer', 'buyer');
insert into public.stores (id, name, owner_id, is_open, daily_bag_limit, bags_remaining, batch_size) values
  ('ac000000-0000-0000-0000-000000000001', 'ph-store-1', 'ab000000-0000-0000-0000-000000000001', true, 5, 5, 2),
  ('ac000000-0000-0000-0000-000000000002', 'ph-store-2', 'ab000000-0000-0000-0000-000000000001', true, 5, 5, 2);

-- reserve_bag keeps the empty search_path.
select pg_temp.ok((select proconfig = array['search_path=""'] from pg_proc
                    where oid = 'public.reserve_bag(uuid, date)'::regprocedure), 'reserve_bag search_path');

-- A retry returns the same booking and takes one bag, not two.
select pg_temp.as_user('ab000000-0000-0000-0000-000000000002');
do $$
declare a public.purchases; b public.purchases;
begin
  a := public.reserve_bag('ac000000-0000-0000-0000-000000000001', (now() at time zone 'Asia/Hebron')::date);
  b := public.reserve_bag('ac000000-0000-0000-0000-000000000001', (now() at time zone 'Asia/Hebron')::date);
  perform pg_temp.ok(a.id = b.id, 'retry returned a different booking');
  perform pg_temp.ok((select bags_remaining = 4 from public.stores
                       where id = 'ac000000-0000-0000-0000-000000000001'), 'retry took a second bag');
end $$;
-- Another bakery the same day is still refused.
select pg_temp.must_fail($$select public.reserve_bag('ac000000-0000-0000-0000-000000000002',
  (now() at time zone 'Asia/Hebron')::date)$$, 'already reserved a bag today');

-- stores: no direct writes, owners included; the RPCs still work.
select pg_temp.as_user('ab000000-0000-0000-0000-000000000001');
select pg_temp.must_fail($$update public.stores set daily_bag_limit = 999
  where id = 'ac000000-0000-0000-0000-000000000001'$$, 'permission denied');
select pg_temp.must_fail($$insert into public.stores (name, owner_id)
  values ('mine', 'ab000000-0000-0000-0000-000000000001')$$, 'permission denied');
select public.set_store_open('ac000000-0000-0000-0000-000000000001', false);
reset role;

-- auth_rate_hit: service role only, allows p_max hits per window.
select pg_temp.as_user(null, 'authenticated');
select pg_temp.must_fail($$select public.auth_rate_hit('x', 1, 60)$$, 'permission denied');
select pg_temp.must_fail($$select count(*) from public.auth_rate_limits$$, 'permission denied');
select pg_temp.as_user(null, 'service_role');
do $$ begin
  perform pg_temp.ok(public.auth_rate_hit('t:1', 2, 3600), 'first hit allowed');
  perform pg_temp.ok(public.auth_rate_hit('t:1', 2, 3600), 'second hit allowed');
  perform pg_temp.ok(not public.auth_rate_hit('t:1', 2, 3600), 'third hit refused');
  perform pg_temp.ok(public.auth_rate_hit('t:2', 2, 3600), 'other bucket unaffected');
end $$;
reset role;

rollback;
