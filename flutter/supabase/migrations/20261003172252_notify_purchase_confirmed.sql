-- "Purchase confirmed" push, sent by the backend.
--
-- The app used to raise this notification itself, on the buyer's phone,
-- right after reserve_bag returned. The server is now the only source of
-- notifications: every new purchase row asks the notify-batch Edge Function
-- to push the confirmation to that buyer's registered devices. pg_net sends
-- the request only after the reserving transaction commits, so a rolled-back
-- reservation never announces itself.
--
-- Same shared secret and endpoint as trigger_notify_batch; the function
-- tells the two apart by the body (purchaseId vs storeId/batchNumber).

create or replace function public.trigger_notify_purchase()
returns trigger
language plpgsql
security definer
set search_path = public
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
    url := 'https://mgmerkaokkffsypnkryj.supabase.co/functions/v1/notify-batch',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-notify-batch-secret', v_secret
    ),
    body := jsonb_build_object('purchaseId', new.id)
  );
  return null;
end;
$$;

revoke execute on function public.trigger_notify_purchase() from public, anon, authenticated;

drop trigger if exists notify_purchase_after_insert on public.purchases;
create trigger notify_purchase_after_insert
  after insert on public.purchases
  for each row
  execute function public.trigger_notify_purchase();
