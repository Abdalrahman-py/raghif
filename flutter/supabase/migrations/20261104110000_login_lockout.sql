-- Sign-in brute-force protection (auth hardening, phase 1).
--
-- The PIN is 4 digits, so without a limit any identity can be guessed in
-- 10,000 tries. login_attempt() counts wrong PINs per account and locks the
-- account for 15 minutes after 5 misses. It is separate from the counters that
-- guard change_my_pin (a signed-in action), so one cannot unlock the other.
--
-- Callable only by service_role (the auth-gateway edge function). The old
-- verify_pin_and_get_profile() stays for the seed/tests but the gateway no
-- longer uses it.
alter table public.profiles
  add column if not exists login_failed_attempts int not null default 0,
  add column if not exists login_locked_until timestamptz;

create or replace function public.login_attempt(
  p_identifier text, p_by text, p_pin text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_p public.profiles;
begin
  if p_by = 'phone' then
    select * into v_p from public.profiles where phone = p_identifier for update;
  else
    select * into v_p from public.profiles where national_id = p_identifier for update;
  end if;

  -- Unknown identity and wrong PIN look the same to the caller.
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

revoke execute on function public.login_attempt(text, text, text)
  from public, anon, authenticated;
grant execute on function public.login_attempt(text, text, text) to service_role;

-- An administrator resetting a PIN also clears a sign-in lock, so support can
-- help someone who locked themselves out.
create or replace function public.admin_set_pin(p_user uuid, p_pin text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_pin is null or p_pin !~ '^[0-9]{4}$' then
    raise exception 'invalid pin';
  end if;
  -- an administrator signs in with email and password, never a PIN
  if exists (select 1 from public.admins where user_id = p_user) then
    raise exception 'cannot reset an administrator PIN';
  end if;
  update public.profiles
     set pin_hash = extensions.crypt(p_pin, extensions.gen_salt('bf')),
         pin_failed_attempts = 0,
         pin_locked_until = null,
         login_failed_attempts = 0,
         login_locked_until = null
   where id = p_user;
  if not found then raise exception 'user not found'; end if;
end;
$$;
