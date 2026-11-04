-- Admin panel, step 1: the schema everything else stands on.
--
--   * admins + is_admin()          who may call the admin_* functions
--   * stores.bag_price / .status   price per bag; active | paused | archived
--   * profiles.account_status      active | disabled (buyers and owners)
--   * profiles.pin_failed_attempts / pin_locked_until   used by change_my_pin
--   * no hard deletes              DELETE revoked from the client roles
--   * archived stores hidden from buyers (but not from their own history)
--   * reserve_bag refuses non-active stores and disabled accounts
--
-- Nothing here is applied to the live project until it has been reviewed.

-- ---------------------------------------------------------------- admins --

create table if not exists public.admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security;
-- No policy and no grant: clients never read this table. is_admin() below
-- (security definer) is the only way in.
revoke all on public.admins from anon, authenticated;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.admins where user_id = auth.uid())
$$;
revoke execute on function public.is_admin() from public, anon, authenticated;
grant execute on function public.is_admin() to authenticated, service_role;

-- --------------------------------------------------------------- columns --

alter table public.stores
  add column if not exists bag_price numeric(6, 2) not null default 3
    check (bag_price >= 0),
  add column if not exists status text not null default 'active'
    check (status in ('active', 'paused', 'archived'));

alter table public.profiles
  add column if not exists account_status text not null default 'active'
    check (account_status in ('active', 'disabled')),
  add column if not exists pin_failed_attempts int not null default 0,
  add column if not exists pin_locked_until timestamptz;

create index if not exists stores_status_idx on public.stores (status);

-- authenticated holds table-level INSERT/UPDATE on stores, so the new columns
-- would be writable by the bakery owner. Only the admin functions (which run
-- as the function owner) and service_role may change them.
create or replace function public.stores_guard_admin_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('anon', 'authenticated') then
    if tg_op = 'INSERT' then
      new.status := 'active';
      new.bag_price := 3;
    elsif new.status is distinct from old.status
       or new.bag_price is distinct from old.bag_price then
      raise exception 'status and bag_price are managed by the administrator';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists stores_guard_admin_columns on public.stores;
create trigger stores_guard_admin_columns
  before insert or update on public.stores
  for each row execute function public.stores_guard_admin_columns();

-- ------------------------------------------------------------ no deletes --

-- Deleting a store or profile cascades to every booking it ever had.
-- Archiving and disabling replace it.
revoke delete on public.stores, public.profiles from anon, authenticated;

-- ------------------------------------------------------------ visibility --

-- True when [p_user] has ever booked at [p_store]. Security definer so the
-- stores policy below can ask without recursing through purchases' own policy.
create or replace function public.user_has_purchase_at(p_store uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.purchases
     where store_id = p_store and user_id = auth.uid()
  )
$$;
revoke execute on function public.user_has_purchase_at(uuid)
  from public, anon, authenticated;
grant execute on function public.user_has_purchase_at(uuid)
  to authenticated, service_role;

drop policy if exists stores_select_public on public.stores;

-- anon (the store list before sign-in): everything except archived.
create policy stores_select_anon on public.stores
  for select to anon
  using (status <> 'archived');

-- Signed-in users: the same, plus their own store and any store they have a
-- booking at, so an old receipt never loses its bakery name.
create policy stores_select_authenticated on public.stores
  for select to authenticated
  using (
    status <> 'archived'
    or owner_id = (select auth.uid())
    or public.user_has_purchase_at(id)
  );

-- ------------------------------------------------------------- reserving --

-- Same function as before (today only, stores row locked first, then the
-- purchase), plus two refusals: a store that is not active, and a disabled
-- account.
create or replace function public.reserve_bag(p_store_id uuid, p_purchase_date date)
returns public.purchases language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_store public.stores; v_sold int; v_p public.purchases;
 v_today date := (now() at time zone 'Asia/Hebron')::date;
begin
 if v_uid is null then raise exception 'not authenticated'; end if;
 if p_purchase_date is distinct from v_today then raise exception 'reservations are for today only'; end if;
 select * into v_store from public.stores where id = p_store_id for update;
 if exists (select 1 from public.profiles where id = v_uid and account_status = 'disabled') then
  raise exception 'account disabled'; end if;
 select count(*) into v_sold from public.purchases where store_id = p_store_id and purchase_date = v_today;
 if v_store.id is null or v_store.status <> 'active' or not v_store.is_open
    or v_store.bags_remaining <= 0 or v_sold >= v_store.daily_bag_limit then
  raise exception 'store closed or sold out'; end if;
 insert into public.purchases(store_id, user_id, purchase_date, batch_number, status)
 values (p_store_id, v_uid, v_today, v_sold / greatest(v_store.batch_size, 1) + 1, 'waiting') returning * into v_p;
 update public.stores set bags_remaining = greatest(least(bags_remaining - 1, daily_bag_limit - v_sold - 1), 0) where id = p_store_id;
 return v_p;
exception when unique_violation then raise exception 'already reserved a bag today';
end $$;

-- --------------------------------------------------------- sign-in gate --

-- Why this identity may not sign in, or null when it may. The auth gateway
-- asks after the PIN checks out, so a disabled account is told so instead of
-- "wrong PIN". Service role only.
create or replace function public.account_login_block(p_user uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p.account_status = 'disabled' then 'account_disabled'
    when exists (
      select 1 from public.stores s
       where s.owner_id = p.id and s.status = 'archived'
    ) and not exists (
      select 1 from public.stores s
       where s.owner_id = p.id and s.status <> 'archived'
    ) then 'store_archived'
    else null
  end
  from public.profiles p
  where p.id = p_user
$$;
revoke execute on function public.account_login_block(uuid)
  from public, anon, authenticated;
grant execute on function public.account_login_block(uuid) to service_role;
