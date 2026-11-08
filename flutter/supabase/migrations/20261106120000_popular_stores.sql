-- The signed-out home screen shows the busiest bakeries, not all of them.
--
-- "Busiest" = most bookings in the last 7 days (today and the six days before,
-- Asia/Hebron). The function returns only store ids and a count: no buyer data
-- leaves the database, so it is safe to let signed-out visitors call it.
-- Archived and paused bakeries are left out.

create or replace function public.popular_stores(p_limit int default 5)
returns table (store_id uuid, bookings bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select s.id, count(p.id)::bigint
    from public.stores s
    left join public.purchases p
      on p.store_id = s.id
     and p.purchase_date >= ((now() at time zone 'Asia/Hebron')::date - 6)
   where s.status = 'active'
   group by s.id
   order by count(p.id) desc, s.name
   limit greatest(1, least(coalesce(p_limit, 5), 20));
$$;

revoke all on function public.popular_stores(int) from public;
grant execute on function public.popular_stores(int) to anon, authenticated;
