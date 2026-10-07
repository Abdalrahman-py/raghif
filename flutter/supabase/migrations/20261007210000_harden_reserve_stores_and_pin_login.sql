-- Backend hardening from the 2026-10 review (docs/BACKEND-REVIEW-2026-10.md).
--
-- 1. reserve_bag stops trusting the client's calendar. The date must be
--    "today" or "tomorrow" in Gaza, by the server's clock. Before, any date
--    was accepted, so one national ID could hold one bag per *invented* date
--    and a wrong phone clock could book into the past. The unique
--    (user_id, purchase_date) constraint only enforces "one bag per day" if
--    the set of valid days is bounded.
-- 2. reserve_bag is idempotent. A retry after a dropped response (the normal
--    failure mode on a Gaza network) returns the purchase that already
--    exists instead of "already reserved a bag today", which told a buyer who
--    HAD a reservation that they did not.
-- 3. stores can no longer be written directly. The owner UPDATE policy let an
--    owner set bags_remaining / daily_bag_limit with a bare UPDATE, bypassing
--    save_store_allocation and its lock, and the DELETE policy let an owner
--    cascade-delete every purchase of the store. Owners change a store only
--    through the RPCs; buyers never could.
-- 4. PIN login gets a lockout. A 4-digit PIN is 10,000 guesses; verify_pin_
--    and_get_profile now counts failures per profile and refuses further
--    attempts for 15 minutes after 5. Counters live in columns that are not
--    in the authenticated column grant, so the app can neither read nor reset
--    them. A miss on an unknown ID still burns one bcrypt so the response time
--    does not reveal which IDs exist.
-- 5. create_profile validates the PIN shape server-side (exactly 4 digits).

-- ----------------------------------------------------------- reserve_bag --
create or replace function public.reserve_bag(p_store_id uuid, p_purchase_date date)
returns public.purchases
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_today date := (now() at time zone 'Asia/Gaza')::date;
  v_store public.stores;
  v_existing public.purchases;
  v_batch_number int;
  v_purchase public.purchases;
begin
  if v_user_id is null then
    raise exception 'not authenticated' using errcode = 'P0001';
  end if;

  if p_purchase_date is null
     or p_purchase_date < v_today or p_purchase_date > v_today + 1 then
    raise exception 'invalid purchase date' using errcode = 'P0001';
  end if;

  -- Serialises every reservation (and allocation change) for this store.
  select * into v_store from public.stores where id = p_store_id for update;
  if not found then
    raise exception 'store closed or sold out' using errcode = 'P0001';
  end if;

  -- Retry of a reservation that already went through: hand it back.
  select * into v_existing from public.purchases
   where user_id = v_user_id and purchase_date = p_purchase_date;
  if found then
    if v_existing.store_id = p_store_id then
      return v_existing;
    end if;
    raise exception 'already reserved a bag today' using errcode = 'P0001';
  end if;

  if not v_store.is_open or v_store.bags_remaining <= 0 then
    raise exception 'store closed or sold out' using errcode = 'P0001';
  end if;

  select floor(count(*)::numeric / greatest(v_store.batch_size, 1))::int + 1
    into v_batch_number
    from public.purchases
   where store_id = p_store_id and purchase_date = p_purchase_date;

  update public.stores set bags_remaining = bags_remaining - 1 where id = p_store_id;

  insert into public.purchases (store_id, user_id, purchase_date, batch_number, status)
  values (p_store_id, v_user_id, p_purchase_date, v_batch_number, 'waiting')
  returning * into v_purchase;

  return v_purchase;
exception
  -- The same buyer racing themselves across two different stores: the store
  -- locks do not collide, the unique constraint does.
  when unique_violation then
    raise exception 'already reserved a bag today' using errcode = 'P0001';
end;
$$;

revoke execute on function public.reserve_bag(uuid, date) from public, anon;
grant execute on function public.reserve_bag(uuid, date) to authenticated;

-- ---------------------------------------------------------------- stores --
-- Writes are RPC-only (save_store_allocation, set_store_open). Reads stay
-- public: buyers browse without an account.
drop policy if exists "stores_owner_insert" on public.stores;
drop policy if exists "stores_owner_update" on public.stores;
drop policy if exists "stores_owner_delete" on public.stores;
revoke insert, update, delete on public.stores from anon, authenticated;

-- ------------------------------------------------------ PIN login lockout --
alter table public.profiles
  add column if not exists failed_pin_attempts int not null default 0,
  add column if not exists pin_locked_until timestamptz;
-- Deliberately absent from the `grant select (...)` list in
-- 20260930130626_lock_direct_writes.sql: the app cannot see or reset these.

create or replace function public.verify_pin_and_get_profile(
  p_identifier text, p_by text, p_pin text)
returns public.profiles
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  c_max_attempts constant int := 5;
  c_lockout constant interval := interval '15 minutes';
  v_profile public.profiles;
begin
  if p_by = 'phone' then
    select * into v_profile from public.profiles where phone = p_identifier for update;
  else
    select * into v_profile from public.profiles where national_id = p_identifier for update;
  end if;

  if v_profile.id is null then
    -- Spend the same bcrypt time as a real check.
    perform extensions.crypt(coalesce(p_pin, ''), extensions.gen_salt('bf'));
    return null;
  end if;

  if v_profile.pin_locked_until is not null and v_profile.pin_locked_until > now() then
    return null;
  end if;

  if v_profile.pin_hash is null
     or extensions.crypt(coalesce(p_pin, ''), v_profile.pin_hash) <> v_profile.pin_hash then
    update public.profiles
       set failed_pin_attempts = case
             when failed_pin_attempts + 1 >= c_max_attempts then 0
             else failed_pin_attempts + 1 end,
           pin_locked_until = case
             when failed_pin_attempts + 1 >= c_max_attempts then now() + c_lockout
             else pin_locked_until end
     where id = v_profile.id;
    return null;
  end if;

  if v_profile.failed_pin_attempts <> 0 or v_profile.pin_locked_until is not null then
    update public.profiles
       set failed_pin_attempts = 0, pin_locked_until = null
     where id = v_profile.id
    returning * into v_profile;
  end if;

  return v_profile;
end;
$$;

revoke execute on function public.verify_pin_and_get_profile(text, text, text)
  from public, anon, authenticated;
grant execute on function public.verify_pin_and_get_profile(text, text, text) to service_role;

-- ---------------------------------------------------------- create_profile --
create or replace function public.create_profile(
  p_id uuid,
  p_phone text,
  p_national_id text,
  p_pin text,
  p_name text,
  p_jawwal_pay_number text,
  p_role text default 'buyer',
  p_verification_status text default 'pending'
)
returns public.profiles
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_profile public.profiles;
begin
  if p_pin is null or p_pin !~ '^[0-9]{4}$' then
    raise exception 'PIN must be exactly 4 digits' using errcode = 'P0001';
  end if;

  insert into public.profiles (id, phone, national_id, pin_hash, name, jawwal_pay_number, role, verification_status)
  values (p_id, p_phone, p_national_id, extensions.crypt(p_pin, extensions.gen_salt('bf')), p_name, p_jawwal_pay_number, p_role, p_verification_status)
  returning * into v_profile;
  return v_profile;
end;
$$;

revoke execute on function public.create_profile(uuid, text, text, text, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.create_profile(uuid, text, text, text, text, text, text, text)
  to service_role;
