-- Admin panel, step 5: two helpers only the admin-api edge function calls.
--
--   admin_revoke_sessions(user)   sign a user out everywhere: used when an
--                                 account is disabled, a bakery is archived or
--                                 a PIN is reset. Deleting auth.sessions
--                                 cascades to auth.refresh_tokens, so no new
--                                 access token can be minted; an access token
--                                 already issued lives out its (short) expiry.
--   admin_set_pin(user, pin)      stores a new PIN (bcrypt) and clears the
--                                 failed-attempt counters.
--
-- Service role only. They carry no is_admin() guard: the edge function proves
-- the caller is the administrator before it uses the service key.

create or replace function public.admin_revoke_sessions(p_user uuid)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count int;
begin
  delete from auth.sessions where user_id = p_user;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

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
         pin_locked_until = null
   where id = p_user;
  if not found then raise exception 'user not found'; end if;
end;
$$;

revoke execute on function public.admin_revoke_sessions(uuid)
  from public, anon, authenticated;
revoke execute on function public.admin_set_pin(uuid, text)
  from public, anon, authenticated;
grant execute on function public.admin_revoke_sessions(uuid) to service_role;
grant execute on function public.admin_set_pin(uuid, text) to service_role;
