create or replace function public.notify_next_batch(p_store_id uuid, p_purchase_date date)
returns setof public.purchases
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid := auth.uid();
  v_next_batch int;
begin
  if not exists (select 1 from public.stores where id = p_store_id and owner_id = v_owner_id) then
    raise exception 'not the store owner' using errcode = 'P0001';
  end if;

  select min(batch_number) into v_next_batch
    from public.purchases
    where store_id = p_store_id and purchase_date = p_purchase_date and status = 'waiting';

  if v_next_batch is null then
    raise exception 'no waiting batch to notify' using errcode = 'P0001';
  end if;

  update public.purchases
    set status = 'notified'
    where store_id = p_store_id and purchase_date = p_purchase_date
      and batch_number = v_next_batch and status = 'waiting';

  return query select * from public.purchases
    where store_id = p_store_id and purchase_date = p_purchase_date and batch_number = v_next_batch;
end;
$$;

grant execute on function public.notify_next_batch(uuid, date) to authenticated;
