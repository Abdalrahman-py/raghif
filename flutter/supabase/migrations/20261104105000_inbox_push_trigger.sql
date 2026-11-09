-- Admin panel, step 6: push the inbox rows nobody pushes yet.
--
-- Two kinds of push already leave the database:
--   * 'confirmed'  trigger_notify_purchase (on purchases insert) -> notify-batch
--   * 'ready'      trigger_notify_batch (batch flipped to notified) -> notify-batch
-- Pushing those again from here would buzz the phone twice, so this trigger
-- covers only the rest:
--   * 'postponed'     (the gap AGENTS.md lists: a row was written, no push)
--   * 'announcement'  (written by admin_send_notification)
--
-- It asks the send-push edge function to deliver the row, authenticating with
-- the same Vault secret as the other push triggers. pg_net sends the request
-- only after the surrounding transaction commits, so a rolled-back
-- postponement never announces itself.
--
-- A push problem must never undo the booking or postponement that caused it:
-- every failure here is swallowed into a warning.

create or replace function public.trigger_push_inbox()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_secret text;
begin
  select decrypted_secret into v_secret
    from vault.decrypted_secrets
   where name = 'notify_batch_secret';

  if v_secret is null then
    raise warning 'notify_batch_secret missing from vault; no push dispatched';
    return null;
  end if;

  perform net.http_post(
    url := 'https://mgmerkaokkffsypnkryj.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-notify-batch-secret', v_secret
    ),
    body := jsonb_build_object('inboxId', new.id)
  );
  return null;
exception when others then
  raise warning 'push dispatch failed: %', sqlerrm;
  return null;
end;
$$;

revoke execute on function public.trigger_push_inbox() from public, anon, authenticated;

drop trigger if exists notification_inbox_push on public.notification_inbox;
create trigger notification_inbox_push
  after insert on public.notification_inbox
  for each row
  when (new.kind in ('postponed', 'announcement'))
  execute function public.trigger_push_inbox();
