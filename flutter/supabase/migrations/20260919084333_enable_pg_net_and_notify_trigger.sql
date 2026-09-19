create extension if not exists pg_net;

create or replace function public.trigger_notify_batch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_store_id uuid;
  v_purchase_date date;
begin
  select store_id, purchase_date into v_store_id, v_purchase_date
  from new_rows
  where status = 'notified'
  limit 1;

  if v_store_id is not null then
    perform net.http_post(
      url := 'https://mgmerkaokkffsypnkryj.supabase.co/functions/v1/notify-batch',
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body := jsonb_build_object('storeId', v_store_id, 'purchaseDate', v_purchase_date)
    );
  end if;
  return null;
end;
$$;

drop trigger if exists notify_batch_after_update on public.purchases;
create trigger notify_batch_after_update
  after update on public.purchases
  referencing new table as new_rows
  for each statement
  execute function public.trigger_notify_batch();
