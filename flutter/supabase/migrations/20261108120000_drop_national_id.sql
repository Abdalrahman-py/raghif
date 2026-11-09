-- Remove the national ID from the product, and make the phone number the one
-- identity: it is the sign-in name, the Jawwal Pay wallet number and the
-- uniqueness key (profiles_phone_key already enforces one account per number).
--
-- Why: the ID was never validated against anything, so it prevented no
-- duplicate accounts, but it was stored, shown to bakery owners and embedded in
-- the QR code. The SMS code that will later verify a buyer goes to this same
-- phone number.
--
-- Not yet published, so the columns are dropped outright (no backfill).

-- Legacy helpers that read the ID. The demo seed now lives in supabase/demo/.
drop function if exists public.find_profile_by_national_id(text);
drop function if exists public.verify_pin_and_get_profile(text, text, text);
drop function if exists public.seed_demo_buyers();
drop function if exists public.seed_demo_day(date);
drop function if exists public.seed_demo_stores();

-- Functions whose signature or result mentions the ID or the separate wallet
-- number are dropped and recreated below.
drop function if exists public.check_availability(text, text);
drop function if exists public.create_profile(uuid, text, text, text, text, text, text, text);
drop function if exists public.login_attempt(text, text, text);
drop function if exists public.record_scan(uuid, text, uuid, text, text);
drop function if exists public.admin_list_buyers(text, integer, integer);
drop function if exists public.update_my_profile(text, text, text);
drop function if exists public.verify_my_wallet(text, text);

alter table public.scan_events drop column scanned_national_id;
alter table public.profiles drop column national_id;
alter table public.profiles drop column jawwal_pay_number;

-- ------------------------------------------------------------------ gateway

create function public.check_availability(p_phone text)
returns table (phone_exists boolean)
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles where phone = p_phone and p_phone <> ''
  );
$$;
revoke all on function public.check_availability(text) from public, anon, authenticated;
grant execute on function public.check_availability(text) to service_role;

create function public.create_profile(
  p_id uuid,
  p_phone text,
  p_pin text,
  p_name text,
  p_role text default 'buyer',
  p_verification_status text default 'pending'
) returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
begin
  insert into public.profiles (id, phone, pin_hash, name, role, verification_status)
  values (p_id, p_phone, extensions.crypt(p_pin, extensions.gen_salt('bf')),
          p_name, p_role, p_verification_status)
  returning * into v_profile;
  return v_profile;
end;
$$;
revoke all on function public.create_profile(uuid, text, text, text, text, text) from public, anon, authenticated;
grant execute on function public.create_profile(uuid, text, text, text, text, text) to service_role;

create function public.login_attempt(p_phone text, p_pin text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_p public.profiles;
begin
  select * into v_p from public.profiles where phone = p_phone for update;

  -- Unknown number and wrong PIN look the same to the caller.
  if v_p.id is null then
    return jsonb_build_object('result', 'invalid');
  end if;

  if v_p.login_locked_until is not null and v_p.login_locked_until > now() then
    return jsonb_build_object(
      'result', 'locked',
      'retry_after',
      greatest(1, ceil(extract(epoch from (v_p.login_locked_until - now())))::int));
  end if;

  if v_p.pin_hash is null
     or p_pin is null
     or extensions.crypt(p_pin, v_p.pin_hash) <> v_p.pin_hash then
    if v_p.login_failed_attempts + 1 >= 5 then
      update public.profiles
         set login_failed_attempts = 0,
             login_locked_until = now() + interval '15 minutes'
       where id = v_p.id;
      return jsonb_build_object('result', 'locked', 'retry_after', 900);
    end if;
    update public.profiles
       set login_failed_attempts = login_failed_attempts + 1
     where id = v_p.id;
    return jsonb_build_object('result', 'invalid');
  end if;

  update public.profiles
     set login_failed_attempts = 0, login_locked_until = null
   where id = v_p.id;
  -- never hand the hash back
  return jsonb_build_object('result', 'ok', 'profile', to_jsonb(v_p) - 'pin_hash');
end;
$$;
revoke all on function public.login_attempt(text, text) from public, anon, authenticated;
grant execute on function public.login_attempt(text, text) to service_role;

-- ------------------------------------------------------------------ profile

create function public.update_my_profile(p_name text)
returns table (
  id uuid, phone text, name text, role text, verification_status text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = 'P0001';
  end if;
  if p_name is null or char_length(btrim(p_name)) not between 2 and 100 then
    raise exception 'invalid profile' using errcode = 'P0001';
  end if;
  -- The phone is the sign-in name and the wallet number: changing it is a
  -- support action, never a client one.
  update public.profiles p set name = btrim(p_name) where p.id = v_uid;
  if not found then raise exception 'profile not found' using errcode = 'P0001'; end if;
  return query select p.id, p.phone, p.name, p.role, p.verification_status
    from public.profiles p where p.id = v_uid;
end;
$$;
revoke all on function public.update_my_profile(text) from public, anon;
grant execute on function public.update_my_profile(text) to authenticated, service_role;

-- The phone number is the wallet number. The code is still the fixed stand-in
-- 1234 until an SMS gateway can text a real one to that number.
create function public.verify_my_wallet(p_code text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_p public.profiles;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select * into v_p from public.profiles where id = v_uid for update;
  if v_p.id is null or v_p.account_status <> 'active' or v_p.role <> 'buyer' then
    return 'not_allowed';
  end if;

  if p_code is distinct from '1234' then
    return 'wrong_code';
  end if;

  update public.profiles set verification_status = 'verified' where id = v_uid;
  return 'ok';
end;
$$;
revoke all on function public.verify_my_wallet(text) from public, anon;
grant execute on function public.verify_my_wallet(text) to authenticated, service_role;

-- --------------------------------------------------------------------- scans

create function public.record_scan(
  p_store_id uuid,
  p_outcome text,
  p_purchase_id uuid default null,
  p_scanned_name text default null
) returns public.scan_events
language plpgsql
security definer
set search_path = 'public'
as $$
declare v_event public.scan_events;
begin
  if not exists (select 1 from public.stores where id = p_store_id and owner_id = (select auth.uid()))
  then raise exception 'not the store owner' using errcode = 'P0001'; end if;

  if p_outcome not in ('checkedIn', 'alreadyCollected', 'batchNotCalledYet',
                       'notFoundHere', 'wrongStore', 'invalidCode', 'staleReceipt') then
    raise exception 'unknown scan outcome' using errcode = 'P0001';
  end if;

  if p_purchase_id is not null and not exists (
    select 1 from public.purchases where id = p_purchase_id and store_id = p_store_id
  ) then p_purchase_id := null; end if;

  insert into public.scan_events (store_id, purchase_id, outcome, scanned_name)
  values (p_store_id, p_purchase_id, p_outcome, p_scanned_name)
  returning * into v_event;
  return v_event;
end; $$;
revoke all on function public.record_scan(uuid, text, uuid, text) from public, anon;
grant execute on function public.record_scan(uuid, text, uuid, text) to authenticated, service_role;

-- --------------------------------------------------------------------- admin

create function public.admin_list_buyers(
  p_search text default null, p_limit integer default 50, p_offset integer default 0
) returns table (
  id uuid, name text, phone text, verification_status text, account_status text,
  created_at timestamptz, bookings bigint, collected bigint, missed bigint,
  total_matches bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Asia/Hebron')::date;
  v_q text := nullif(btrim(coalesce(p_search, '')), '');
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  return query
  select p.id, p.name, p.phone, p.verification_status,
         p.account_status, p.created_at,
         coalesce(a.bookings, 0), coalesce(a.collected, 0), coalesce(a.missed, 0),
         count(*) over ()
    from public.profiles p
    left join (
      select user_id,
             count(*) as bookings,
             count(*) filter (where status = 'collected') as collected,
             count(*) filter (where status <> 'collected' and purchase_date < v_today) as missed
        from public.purchases
       group by user_id
    ) a on a.user_id = p.id
   where p.role = 'buyer'
     and (v_q is null
          or p.name ilike '%' || v_q || '%'
          or p.phone ilike '%' || v_q || '%')
   order by p.created_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;
revoke all on function public.admin_list_buyers(text, integer, integer) from public, anon;
grant execute on function public.admin_list_buyers(text, integer, integer) to authenticated, service_role;
