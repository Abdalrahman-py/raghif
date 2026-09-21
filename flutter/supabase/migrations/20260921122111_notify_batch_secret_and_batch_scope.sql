-- Hardens the notify-batch push pipeline on two axes:
--
-- 1. Authorization. The Edge Function runs with verify_jwt off (pg_net has
--    no session to present), which left it an open push relay — store ids
--    are world-readable, so anyone could alert every waiting buyer. The
--    trigger now sends a shared secret, generated here into Vault so it is
--    never committed to the repo.
-- 2. Batch scope. The payload now carries batch_number, and the trigger
--    fires only for rows that actually transitioned into 'notified' (the
--    OLD-table join). Previously any statement leaving a row at 'notified'
--    re-triggered, and the function then pushed to every uncollected
--    earlier batch as well.

do $$
begin
  if not exists (select 1 from vault.secrets where name = 'notify_batch_secret') then
    perform vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'notify_batch_secret',
      'Shared secret sent as x-notify-batch-secret by trigger_notify_batch; '
      'must match the notify-batch Edge Function NOTIFY_BATCH_SECRET env var.'
    );
  end if;
end $$;

create or replace function public.trigger_notify_batch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_secret text;
  r record;
begin
  select decrypted_secret into v_secret
    from vault.decrypted_secrets
    where name = 'notify_batch_secret';

  if v_secret is null then
    raise warning 'notify_batch_secret missing from vault; no push dispatched';
    return null;
  end if;

  -- One POST per batch that just flipped. `distinct` because this is a
  -- statement-level trigger: a batch is many rows, but one notification.
  for r in
    select distinct n.store_id, n.purchase_date, n.batch_number
      from new_rows n
      join old_rows o on o.id = n.id
     where n.status = 'notified'
       and o.status is distinct from 'notified'
  loop
    perform net.http_post(
      url := 'https://mgmerkaokkffsypnkryj.supabase.co/functions/v1/notify-batch',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-notify-batch-secret', v_secret
      ),
      body := jsonb_build_object(
        'storeId', r.store_id,
        'purchaseDate', r.purchase_date,
        'batchNumber', r.batch_number
      )
    );
  end loop;

  return null;
end;
$$;

revoke execute on function public.trigger_notify_batch() from public, anon, authenticated;

-- Recreated to add the OLD transition table.
drop trigger if exists notify_batch_after_update on public.purchases;
create trigger notify_batch_after_update
  after update on public.purchases
  referencing old table as old_rows new table as new_rows
  for each statement
  execute function public.trigger_notify_batch();
