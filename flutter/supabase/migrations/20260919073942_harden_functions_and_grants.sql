create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke execute on function public.reserve_bag(uuid, date) from public, anon;
grant execute on function public.reserve_bag(uuid, date) to authenticated;

revoke execute on function public.notify_next_batch(uuid, date) from public, anon;
grant execute on function public.notify_next_batch(uuid, date) to authenticated;

revoke execute on function public.save_store_allocation(uuid, int, boolean, int, date) from public, anon;
grant execute on function public.save_store_allocation(uuid, int, boolean, int, date) to authenticated;
