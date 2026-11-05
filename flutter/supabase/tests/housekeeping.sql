-- Rollback-only checks for 20261105130000_housekeeping.
begin;

create function pg_temp.ok(ok boolean, msg text) returns void
  language plpgsql as $$
begin
  if not coalesce(ok, false) then raise exception 'check failed: %', msg; end if;
end $$;

insert into auth.users (id) values ('b1000000-0000-0000-0000-0000000000a1');
insert into public.profiles (id, phone, national_id, pin_hash, name, role)
  values ('b1000000-0000-0000-0000-0000000000a1', 'hk-1', 'hk-n1', 'x', 'hk', 'buyer');
insert into public.stores (id, name, is_open, daily_bag_limit, bags_remaining)
  values ('b2000000-0000-0000-0000-0000000000a1', 'hk-store', true, 5, 5);
insert into public.scan_events (store_id, outcome, scanned_at) values
  ('b2000000-0000-0000-0000-0000000000a1', 'checked_in', now() - interval '200 days'),
  ('b2000000-0000-0000-0000-0000000000a1', 'checked_in', now() - interval '10 days');
insert into public.notification_inbox (user_id, purchase_id, kind, title, body, created_at) values
  ('b1000000-0000-0000-0000-0000000000a1', null, 'announcement', 'old', 'x', now() - interval '100 days'),
  ('b1000000-0000-0000-0000-0000000000a1', null, 'announcement', 'new', 'x', now() - interval '1 day');
insert into public.device_tokens (user_id, fcm_token, platform, updated_at) values
  ('b1000000-0000-0000-0000-0000000000a1', 'hk-old', 'android', now() - interval '130 days'),
  ('b1000000-0000-0000-0000-0000000000a1', 'hk-new', 'android', now());

do $$
declare r jsonb;
begin
  r := public.run_housekeeping();
  perform pg_temp.ok((r->>'scan_events')::int >= 1, 'old scan deleted');
  perform pg_temp.ok((r->>'notification_inbox')::int >= 1, 'old inbox row deleted');
  perform pg_temp.ok((r->>'device_tokens')::int >= 1, 'stale token deleted');
  perform pg_temp.ok(exists (select 1 from public.scan_events where store_id = 'b2000000-0000-0000-0000-0000000000a1'), 'recent scan kept');
  perform pg_temp.ok(not exists (select 1 from public.scan_events where store_id = 'b2000000-0000-0000-0000-0000000000a1' and scanned_at < now() - interval '180 days'), 'no old scan left');
  perform pg_temp.ok(exists (select 1 from public.notification_inbox where title = 'new'), 'recent inbox kept');
  perform pg_temp.ok(not exists (select 1 from public.notification_inbox where title = 'old'), 'old inbox gone');
  perform pg_temp.ok(exists (select 1 from public.device_tokens where fcm_token = 'hk-new'), 'fresh token kept');
  perform pg_temp.ok(not exists (select 1 from public.device_tokens where fcm_token = 'hk-old'), 'stale token gone');
  -- nothing the client can call
  perform pg_temp.ok(not has_function_privilege('authenticated', 'public.run_housekeeping()', 'execute'), 'authenticated cannot');
  perform pg_temp.ok(not has_function_privilege('anon', 'public.run_housekeeping()', 'execute'), 'anon cannot');
end $$;

rollback;
