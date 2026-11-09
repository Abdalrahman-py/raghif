-- A buyer is verified by confirming the Jawwal Pay number (replaces the ID and
-- selfie steps, which never checked anything).
--
-- Until the Jawwal Pay gateway can text a real code to the wallet's phone, the
-- code is the fixed value '1234'. THIS IS A STAND-IN: anyone who knows it can
-- verify any number, so "verified" means "tried the number", not "owns it".
-- When the gateway arrives, replace the comparison below with a lookup of the
-- code that was actually sent (and count wrong attempts).
--
--  * verify_my_wallet(number, code): the only way a client reaches 'verified'.
--  * Changing the wallet number through update_my_profile sends a buyer back to
--    'pending', so the verified number is always the one on the profile.
--  * The direct column grants on verification_status / jawwal_pay_number are
--    revoked; the client now goes through the two functions only.

create or replace function public.verify_my_wallet(p_number text, p_code text)
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

  if p_number is null or btrim(p_number) !~ '^05[69][0-9]{7}$' then
    return 'invalid_number';
  end if;

  if p_code is distinct from '1234' then
    return 'wrong_code';
  end if;

  update public.profiles
     set jawwal_pay_number = btrim(p_number),
         verification_status = 'verified'
   where id = v_uid;
  return 'ok';
end;
$$;

revoke all on function public.verify_my_wallet(text, text) from public, anon;
grant execute on function public.verify_my_wallet(text, text) to authenticated;

-- update_my_profile: a different wallet number un-verifies a buyer.
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
  v_wallet text;
  v_role text;
  v_new_wallet text := nullif(btrim(p_jawwal_pay_number), '');
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = 'P0001';
  end if;
  if p_name is null or char_length(btrim(p_name)) not between 2 and 100
     or p_phone is null or btrim(p_phone) !~ '^05[69][0-9]{7}$'
     or (v_new_wallet is not null and v_new_wallet !~ '^05[69][0-9]{7}$') then
    raise exception 'invalid profile' using errcode = 'P0001';
  end if;

  select pr.phone, pr.jawwal_pay_number, pr.role
    into v_current, v_wallet, v_role
    from public.profiles pr where pr.id = v_uid;
  if not found then raise exception 'profile not found' using errcode = 'P0001'; end if;
  if btrim(p_phone) <> v_current then
    raise exception 'phone change requires support' using errcode = 'P0001';
  end if;

  update public.profiles p set name = btrim(p_name),
    jawwal_pay_number = v_new_wallet,
    verification_status = case
      when v_role = 'buyer' and v_new_wallet is distinct from v_wallet
        then 'pending' else p.verification_status end
    where p.id = v_uid;
  return query select p.id, p.phone, p.national_id, p.name, p.role,
    p.jawwal_pay_number, p.verification_status from public.profiles p where p.id = v_uid;
end;
$$;

revoke all on function public.update_my_profile(text, text, text) from public, anon;
grant execute on function public.update_my_profile(text, text, text) to authenticated;

-- The client no longer writes these two columns directly.
revoke update (verification_status, jawwal_pay_number)
  on public.profiles from authenticated;
