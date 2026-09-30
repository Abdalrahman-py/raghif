-- Moves the remaining business logic server-side so the app can stop owning
-- it. Every write the UI performs now has an RPC with its own authorization
-- check, and the two owner-facing aggregates are computed in SQL rather than
-- over a local mirror that could disagree with the server.

create or replace function public.collect_purchase(p_purchase_id uuid)
returns public.purchases
language plpgsql security definer set search_path = public as $$
declare v_purchase public.purchases;
begin
  if not exists (
    select 1 from public.purchases p join public.stores s on s.id = p.store_id
     where p.id = p_purchase_id and s.owner_id = (select auth.uid())
  ) then raise exception 'not the store owner' using errcode = 'P0001'; end if;

  update public.purchases set status = 'collected'
   where id = p_purchase_id and status <> 'collected' returning * into v_purchase;

  if v_purchase.id is null then
    select * into v_purchase from public.purchases where id = p_purchase_id;
  end if;
  return v_purchase;
end; $$;

create or replace function public.set_store_open(p_store_id uuid, p_is_open boolean)
returns public.stores
language plpgsql security definer set search_path = public as $$
declare v_store public.stores;
begin
  if not exists (select 1 from public.stores where id = p_store_id and owner_id = (select auth.uid()))
  then raise exception 'not the store owner' using errcode = 'P0001'; end if;
  update public.stores set is_open = p_is_open where id = p_store_id returning * into v_store;
  return v_store;
end; $$;

-- Pickup audit trail. A failed or unrecognised scan is still recorded, which
-- is why purchase_id is nullable.
create or replace function public.record_scan(
  p_store_id uuid, p_outcome text, p_purchase_id uuid default null,
  p_scanned_name text default null, p_scanned_national_id text default null)
returns public.scan_events
language plpgsql security definer set search_path = public as $$
declare v_event public.scan_events;
begin
  if not exists (select 1 from public.stores where id = p_store_id and owner_id = (select auth.uid()))
  then raise exception 'not the store owner' using errcode = 'P0001'; end if;
  insert into public.scan_events (store_id, purchase_id, outcome, scanned_name, scanned_national_id)
  values (p_store_id, p_purchase_id, p_outcome, p_scanned_name, p_scanned_national_id)
  returning * into v_event;
  return v_event;
end; $$;

-- Buyer's own pin. A display preference, but server-side so a reinstall or a
-- second handset keeps the buyer's list order.
create or replace function public.set_store_pinned(p_store_id uuid, p_pinned boolean)
returns void
language plpgsql security definer set search_path = public as $$
declare v_user_id uuid := (select auth.uid());
begin
  if v_user_id is null then raise exception 'not authenticated' using errcode = 'P0001'; end if;
  if p_pinned then
    insert into public.store_pins (user_id, store_id) values (v_user_id, p_store_id)
    on conflict (user_id, store_id) do nothing;
  else
    delete from public.store_pins where user_id = v_user_id and store_id = p_store_id;
  end if;
end; $$;

-- Replaces the 5-arg version: the purchase window used to be saved only
-- on-device, so a buyer on another handset never saw it.
drop function if exists public.save_store_allocation(uuid, int, boolean, int, date);

create or replace function public.save_store_allocation(
  p_store_id uuid, p_daily_bag_limit int, p_is_open boolean, p_batch_size int,
  p_purchase_date date, p_open_time time default null, p_close_time time default null)
returns public.stores
language plpgsql security definer set search_path = public as $$
declare v_sold int; v_store public.stores;
begin
  if not exists (select 1 from public.stores where id = p_store_id and owner_id = (select auth.uid()))
  then raise exception 'not the store owner' using errcode = 'P0001'; end if;

  select count(*) into v_sold from public.purchases
   where store_id = p_store_id and purchase_date = p_purchase_date;

  update public.stores
     set daily_bag_limit = p_daily_bag_limit, is_open = p_is_open,
         batch_size = greatest(p_batch_size, 1),
         bags_remaining = greatest(p_daily_bag_limit - v_sold, 0),
         open_time = p_open_time, close_time = p_close_time
   where id = p_store_id returning * into v_store;
  return v_store;
end; $$;

-- SECURITY DEFINER because these span profiles rows the owner may read only
-- through the purchase join; the owner check in each body is what authorizes.
create or replace function public.store_customers(p_store_id uuid)
returns table (user_id uuid, name text, phone text, total_purchases bigint, last_purchase_date date)
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.stores where id = p_store_id and owner_id = (select auth.uid()))
  then raise exception 'not the store owner' using errcode = 'P0001'; end if;
  return query
    select pr.id, coalesce(pr.name, ''), coalesce(pr.phone, ''), count(p.id), max(p.purchase_date)
      from public.purchases p join public.profiles pr on pr.id = p.user_id
     where p.store_id = p_store_id
     group by pr.id, pr.name, pr.phone
     order by max(p.purchase_date) desc, pr.name;
end; $$;

-- `not_collected` is the end-of-day leftover: reserved, never picked up.
create or replace function public.store_daily_summaries(p_store_id uuid, p_limit int default 30)
returns table (purchase_date date, sold bigint, collected bigint, not_collected bigint)
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from public.stores where id = p_store_id and owner_id = (select auth.uid()))
  then raise exception 'not the store owner' using errcode = 'P0001'; end if;
  return query
    select p.purchase_date, count(*),
           count(*) filter (where p.status = 'collected'),
           count(*) filter (where p.status <> 'collected')
      from public.purchases p where p.store_id = p_store_id
     group by p.purchase_date order by p.purchase_date desc limit greatest(p_limit, 1);
end; $$;

grant execute on function public.collect_purchase(uuid) to authenticated;
grant execute on function public.set_store_open(uuid, boolean) to authenticated;
grant execute on function public.record_scan(uuid, text, uuid, text, text) to authenticated;
grant execute on function public.set_store_pinned(uuid, boolean) to authenticated;
grant execute on function public.save_store_allocation(uuid, int, boolean, int, date, time, time) to authenticated;
grant execute on function public.store_customers(uuid) to authenticated;
grant execute on function public.store_daily_summaries(uuid, int) to authenticated;
