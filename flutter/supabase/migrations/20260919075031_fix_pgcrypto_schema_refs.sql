create or replace function public.create_profile(
  p_id uuid,
  p_phone text,
  p_national_id text,
  p_pin text,
  p_name text,
  p_jawwal_pay_number text,
  p_role text default 'buyer'
)
returns public.profiles
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_profile public.profiles;
begin
  insert into public.profiles (id, phone, national_id, pin_hash, name, jawwal_pay_number, role)
  values (p_id, p_phone, p_national_id, extensions.crypt(p_pin, extensions.gen_salt('bf')), p_name, p_jawwal_pay_number, p_role)
  returning * into v_profile;
  return v_profile;
end;
$$;

create or replace function public.verify_pin_and_get_profile(p_identifier text, p_by text, p_pin text)
returns public.profiles
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_profile public.profiles;
begin
  if p_by = 'phone' then
    select * into v_profile from public.profiles where phone = p_identifier;
  else
    select * into v_profile from public.profiles where national_id = p_identifier;
  end if;

  if v_profile.id is null then
    return null;
  end if;

  if v_profile.pin_hash is null or extensions.crypt(p_pin, v_profile.pin_hash) <> v_profile.pin_hash then
    return null;
  end if;

  return v_profile;
end;
$$;
