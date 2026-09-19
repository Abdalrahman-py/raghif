create or replace function public.save_store_allocation(
  p_store_id uuid,
  p_daily_bag_limit int,
  p_is_open boolean,
  p_batch_size int,
  p_purchase_date date
)
returns public.stores
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid := auth.uid();
  v_sold int;
  v_store public.stores;
begin
  if not exists (select 1 from public.stores where id = p_store_id and owner_id = v_owner_id) then
    raise exception 'not the store owner' using errcode = 'P0001';
  end if;

  select count(*) into v_sold
    from public.purchases
    where store_id = p_store_id and purchase_date = p_purchase_date;

  update public.stores
    set daily_bag_limit = p_daily_bag_limit,
        is_open = p_is_open,
        batch_size = greatest(p_batch_size, 1),
        bags_remaining = greatest(p_daily_bag_limit - v_sold, 0)
    where id = p_store_id
    returning * into v_store;

  return v_store;
end;
$$;

grant execute on function public.save_store_allocation(uuid, int, boolean, int, date) to authenticated;
