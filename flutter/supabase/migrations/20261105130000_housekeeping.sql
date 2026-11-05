-- Scheduled housekeeping (launch plan, phase 8).
--
-- Old, low-value rows are removed once a day so tables stay small:
--   * scan_events older than 180 days (the owner's scan log),
--   * notification_inbox rows older than 90 days,
--   * device tokens not refreshed in 120 days (a phone that never came back).
-- Bookings, payments, accounts and bakeries are never touched here.
--
-- run_housekeeping() holds the logic (and is tested); a pg_cron job calls it
-- when the extension is available on the project.
create or replace function public.run_housekeeping()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_scans int;
  v_inbox int;
  v_tokens int;
begin
  delete from public.scan_events where scanned_at < now() - interval '180 days';
  get diagnostics v_scans = row_count;
  delete from public.notification_inbox where created_at < now() - interval '90 days';
  get diagnostics v_inbox = row_count;
  delete from public.device_tokens where updated_at < now() - interval '120 days';
  get diagnostics v_tokens = row_count;
  return jsonb_build_object('scan_events', v_scans, 'notification_inbox', v_inbox,
                            'device_tokens', v_tokens);
end $$;

revoke execute on function public.run_housekeeping() from public, anon, authenticated;

-- Schedule it daily, shortly after midnight Asia/Hebron (21:30 UTC is 00:30 in
-- winter time, 00:30 or 23:30 around the clock change: the exact minute does
-- not matter). Skipped where pg_cron cannot be installed (the local test
-- database), and re-running replaces the job instead of duplicating it.
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron with schema pg_catalog;
    perform cron.unschedule(jobid) from cron.job where jobname = 'raghif-housekeeping';
    perform cron.schedule('raghif-housekeeping', '30 21 * * *',
                          'select public.run_housekeeping()');
  end if;
end $$;
