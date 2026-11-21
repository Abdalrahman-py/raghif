-- Pre-launch hardening, re-applied from the unmerged
-- chore/backend-hardening-and-spec-rewrite branch onto the current RPCs.
--
-- 1. stores is RPC-only for clients. The owner INSERT/UPDATE policies let an
--    owner set bags_remaining / daily_bag_limit with a bare UPDATE, skipping
--    save_store_allocation and its lock. The app writes stores only through
--    set_store_open / save_store_allocation, and the admin panel through
--    admin-api (service role), so nothing legitimate uses the direct path.
-- 2. reserve_bag is idempotent. A retry after a dropped response (the usual
--    failure on a weak network) gets the booking it already holds instead of
--    "already reserved a bag today". Today-only, Asia/Hebron, the lock order
--    (stores row first) and the capacity checks are unchanged.
-- 3. auth_rate_hit: a fixed-window counter the auth gateway uses to slow down
--    phone-number enumeration through register / check-availability.

-- ------------------------------------------------------------------ stores --
drop policy if exists "stores_owner_insert" on public.stores;
drop policy if exists "stores_owner_update" on public.stores;
drop policy if exists "stores_owner_delete" on public.stores;
revoke insert, update, delete on public.stores from anon, authenticated;

-- ------------------------------------------------------------- reserve_bag --
create or replace function public.reserve_bag(p_store_id uuid, p_purchase_date date)
returns public.purchases
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_store public.stores;
  v_sold int;
  v_p public.purchases;
  v_today date := (now() at time zone 'Asia/Hebron')::date;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if p_purchase_date is distinct from v_today then
    raise exception 'reservations are for today only';
  end if;
  -- Lock order: stores row first, then the purchase row.
  select * into v_store from public.stores where id = p_store_id for update;
  if exists (select 1 from public.profiles where id = v_uid and account_status = 'disabled') then
    raise exception 'account disabled';
  end if;

  -- A retry of a booking that already went through: hand it back.
  select * into v_p from public.purchases
   where user_id = v_uid and purchase_date = v_today
   for update;
  if found then
    if v_p.store_id = p_store_id then return v_p; end if;
    raise exception 'already reserved a bag today';
  end if;

  select count(*) into v_sold from public.purchases
   where store_id = p_store_id and purchase_date = v_today;
  if v_store.id is null or v_store.status <> 'active' or not v_store.is_open
     or v_store.bags_remaining <= 0 or v_sold >= v_store.daily_bag_limit then
    raise exception 'store closed or sold out';
  end if;
  insert into public.purchases(store_id, user_id, purchase_date, batch_number, status)
  values (p_store_id, v_uid, v_today, v_sold / greatest(v_store.batch_size, 1) + 1, 'waiting')
  returning * into v_p;
  update public.stores
     set bags_remaining = greatest(least(bags_remaining - 1, daily_bag_limit - v_sold - 1), 0)
   where id = p_store_id;
  return v_p;
exception when unique_violation then
  raise exception 'already reserved a bag today';
end;
$$;
revoke all on function public.reserve_bag(uuid, date) from public, anon;
grant execute on function public.reserve_bag(uuid, date) to authenticated;

-- ------------------------------------------------------------ rate limits --
create table if not exists public.auth_rate_limits (
  bucket text not null,
  window_start timestamptz not null,
  hits int not null default 0,
  primary key (bucket, window_start)
);
alter table public.auth_rate_limits enable row level security;
revoke all on public.auth_rate_limits from anon, authenticated;

-- Counts one hit on `p_bucket` in the current fixed window and says whether
-- the caller is still within `p_max`. Old windows are pruned as it goes.
-- Service role only (the auth gateway).
create or replace function public.auth_rate_hit(p_bucket text, p_max int, p_window_seconds int)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_start timestamptz := to_timestamp(
    floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds);
  v_hits int;
begin
  insert into public.auth_rate_limits as r (bucket, window_start, hits)
  values (p_bucket, v_start, 1)
  on conflict (bucket, window_start) do update set hits = r.hits + 1
  returning hits into v_hits;
  delete from public.auth_rate_limits where window_start < now() - interval '1 day';
  return v_hits <= p_max;
end;
$$;
revoke all on function public.auth_rate_hit(text, int, int) from public, anon, authenticated;
grant execute on function public.auth_rate_hit(text, int, int) to service_role;
