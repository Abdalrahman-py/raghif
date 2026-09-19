create or replace function public.reserve_bag(p_store_id uuid, p_purchase_date date)
returns public.purchases
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_batch_size int;
  v_batch_number int;
  v_purchase public.purchases;
begin
  if v_user_id is null then
    raise exception 'not authenticated' using errcode = 'P0001';
  end if;

  perform 1 from public.stores where id = p_store_id for update;

  if not exists (
    select 1 from public.stores
    where id = p_store_id and is_open = true and bags_remaining > 0
  ) then
    raise exception 'store closed or sold out' using errcode = 'P0001';
  end if;

  select batch_size into v_batch_size from public.stores where id = p_store_id;

  select coalesce(floor(count(*) / v_batch_size), 0) + 1 into v_batch_number
    from public.purchases
    where store_id = p_store_id and purchase_date = p_purchase_date;

  update public.stores
    set bags_remaining = bags_remaining - 1
    where id = p_store_id;

  insert into public.purchases (store_id, user_id, purchase_date, batch_number, status)
  values (p_store_id, v_user_id, p_purchase_date, v_batch_number, 'waiting')
  returning * into v_purchase;

  return v_purchase;
exception
  when unique_violation then
    raise exception 'already reserved a bag today' using errcode = 'P0001';
end;
$$;

grant execute on function public.reserve_bag(uuid, date) to authenticated;
