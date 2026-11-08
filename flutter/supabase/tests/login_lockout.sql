-- Rollback-only checks for 20261104110000_login_lockout.
begin;

create function pg_temp.ok(ok boolean, msg text) returns void
  language plpgsql as $$
begin
  if not coalesce(ok, false) then raise exception 'check failed: %', msg; end if;
end $$;

insert into auth.users (id) values ('c0000000-0000-0000-0000-000000000001'),
                                   ('c0000000-0000-0000-0000-000000000002');
insert into public.profiles (id, phone, pin_hash, name, role) values
  ('c0000000-0000-0000-0000-000000000001', 'lk-1',
     extensions.crypt('4829', extensions.gen_salt('bf')), 'lk-a', 'buyer'),
  ('c0000000-0000-0000-0000-000000000002', 'lk-2',
     extensions.crypt('4829', extensions.gen_salt('bf')), 'lk-b', 'buyer');

do $$
declare r jsonb;
begin
  -- right PIN works and never returns the hash
  r := public.login_attempt('lk-1', '4829');
  perform pg_temp.ok(r->>'result' = 'ok' and r->'profile'->>'id' = 'c0000000-0000-0000-0000-000000000001', 'ok login');
  perform pg_temp.ok(not (r->'profile' ? 'pin_hash'), 'hash not returned');

  -- unknown number looks like a wrong PIN
  perform pg_temp.ok(public.login_attempt('nobody', '4829')->>'result' = 'invalid', 'unknown id');

  -- four misses stay "invalid", the fifth locks
  for i in 1..4 loop
    perform pg_temp.ok(public.login_attempt('lk-1', '0000')->>'result' = 'invalid', 'miss ' || i);
  end loop;
  r := public.login_attempt('lk-1', '0000');
  perform pg_temp.ok(r->>'result' = 'locked' and (r->>'retry_after')::int = 900, 'fifth miss locks');

  -- locked: even the right PIN is refused, and the counter does not run on
  r := public.login_attempt('lk-1', '4829');
  perform pg_temp.ok(r->>'result' = 'locked' and (r->>'retry_after')::int between 1 and 900, 'locked refuses right PIN');

  -- another account is unaffected
  perform pg_temp.ok(public.login_attempt('lk-2', '4829')->>'result' = 'ok', 'other account fine');

  -- lock expires
  update public.profiles set login_locked_until = now() - interval '1 second' where phone = 'lk-1';
  perform pg_temp.ok(public.login_attempt('lk-1', '4829')->>'result' = 'ok', 'works after expiry');

  -- a success clears earlier misses
  perform public.login_attempt('lk-2', '1111');
  perform public.login_attempt('lk-2', '4829');
  perform pg_temp.ok((select login_failed_attempts = 0 from public.profiles where phone = 'lk-2'), 'success resets counter');

  -- admin PIN reset clears a lock
  update public.profiles set login_locked_until = now() + interval '10 minutes', login_failed_attempts = 3 where phone = 'lk-2';
  perform public.admin_set_pin('c0000000-0000-0000-0000-000000000002', '5921');
  perform pg_temp.ok(public.login_attempt('lk-2', '5921')->>'result' = 'ok', 'admin reset unlocks');
end $$;

-- only the service role may call it
do $$ begin
  perform pg_temp.ok(not has_function_privilege('authenticated', 'public.login_attempt(text,text)', 'execute'), 'authenticated cannot');
  perform pg_temp.ok(not has_function_privilege('anon', 'public.login_attempt(text,text)', 'execute'), 'anon cannot');
  perform pg_temp.ok(has_function_privilege('service_role', 'public.login_attempt(text,text)', 'execute'), 'service_role can');
end $$;
-- ...and the client cannot read or write the counters
do $$ begin
  perform pg_temp.ok(not has_column_privilege('authenticated', 'public.profiles', 'login_locked_until', 'update'), 'no client write');
  perform pg_temp.ok(not has_column_privilege('authenticated', 'public.profiles', 'login_failed_attempts', 'select'), 'no client read');
end $$;

rollback;
