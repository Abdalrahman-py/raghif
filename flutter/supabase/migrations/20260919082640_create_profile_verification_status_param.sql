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
  insert into public.profiles (id, phone, national_id, pin_hash, name, jawwal_pay_number, role, verification_status)
  values (p_id, p_phone, p_national_id, extensions.crypt(p_pin, extensions.gen_salt('bf')), p_name, p_jawwal_pay_number, p_role, p_verification_status)
  returning * into v_profile;
  return v_profile;
end;
$$;

revoke execute on function public.create_profile(uuid, text, text, text, text, text, text, text) from public, anon, authenticated;
grant execute on function public.create_profile(uuid, text, text, text, text, text, text, text) to service_role;

drop function if exists public.create_profile(uuid, text, text, text, text, text, text);
