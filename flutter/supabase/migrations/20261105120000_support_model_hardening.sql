-- Support-handled account recovery (launch plan, phase 6, "support" option).
--
-- There is no SMS gateway, so a forgotten PIN is reset by support through the
-- admin panel. Two consequences:
--
--  1. Everyone may change their own PIN (not only owners): support hands out a
--     random one-time PIN, and the person replaces it with their own.
--  2. The phone number is the identifier support checks against and the number
--     a recovery PIN is sent to, so it can no longer be changed from the app:
--     a stolen session must not be able to move the account to another phone.
--     update_my_profile keeps its signature (older apps send the current number
--     back) but refuses a different one, with a message that says nothing about
--     whether some other number is registered.

create or replace function public.change_my_pin(p_old text, p_new text)
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
  if v_p.id is null or v_p.account_status <> 'active' then
    return 'not_allowed';
  end if;

  if v_p.pin_locked_until is not null and v_p.pin_locked_until > now() then
    return 'locked';
  end if;

  if p_old is null or v_p.pin_hash is null
     or extensions.crypt(p_old, v_p.pin_hash) <> v_p.pin_hash then
    if v_p.pin_failed_attempts + 1 >= 5 then
      update public.profiles
         set pin_failed_attempts = 0,
             pin_locked_until = now() + interval '15 minutes'
       where id = v_uid;
      return 'locked';
    end if;
    update public.profiles
       set pin_failed_attempts = pin_failed_attempts + 1
     where id = v_uid;
    return 'wrong_pin';
  end if;

  if p_new is null or p_new !~ '^[0-9]{4}$' then
    return 'invalid_pin';
  end if;
  if p_new = p_old then
    return 'same_pin';
  end if;
  if p_new ~ '^([0-9])\1{3}$'
     or p_new in ('0123', '1234', '2345', '3456', '4567', '5678', '6789',
                  '3210', '4321', '5432', '6543', '7654', '8765', '9876') then
    return 'weak_pin';
  end if;

  update public.profiles
     set pin_hash = extensions.crypt(p_new, extensions.gen_salt('bf')),
         pin_failed_attempts = 0,
         pin_locked_until = null
   where id = v_uid;
  return 'ok';
end;
$$;

revoke execute on function public.change_my_pin(text, text)
  from public, anon, authenticated;
grant execute on function public.change_my_pin(text, text) to authenticated;

create or replace function public.update_my_profile(
  p_name text, p_phone text, p_jawwal_pay_number text
)
returns table (
  id uuid, phone text, national_id text, name text, role text,
  jawwal_pay_number text, verification_status text
)
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_current text;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = 'P0001';
  end if;
  if p_name is null or char_length(btrim(p_name)) not between 2 and 100
     or p_phone is null or btrim(p_phone) !~ '^05[69][0-9]{7}$'
     or (nullif(btrim(p_jawwal_pay_number), '') is not null
         and btrim(p_jawwal_pay_number) !~ '^05[69][0-9]{7}$') then
    raise exception 'invalid profile' using errcode = 'P0001';
  end if;

  select pr.phone into v_current from public.profiles pr where pr.id = v_uid;
  if not found then raise exception 'profile not found' using errcode = 'P0001'; end if;
  if btrim(p_phone) <> v_current then
    raise exception 'phone change requires support' using errcode = 'P0001';
  end if;

  update public.profiles p set name = btrim(p_name),
    jawwal_pay_number = nullif(btrim(p_jawwal_pay_number), '')
    where p.id = v_uid;
  return query select p.id, p.phone, p.national_id, p.name, p.role,
    p.jawwal_pay_number, p.verification_status from public.profiles p where p.id = v_uid;
end;
$$;

revoke all on function public.update_my_profile(text, text, text) from public, anon;
grant execute on function public.update_my_profile(text, text, text) to authenticated;
