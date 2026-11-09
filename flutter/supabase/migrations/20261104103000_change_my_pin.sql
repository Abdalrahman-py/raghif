-- Admin panel, step 4: a bakery owner changes their own PIN from the app.
--
-- The panel hands an owner a random PIN once; this lets them replace it.
-- Rules:
--   * owners only (buyers keep the PIN they registered with for now)
--   * the current PIN must be right
--   * 5 wrong tries lock the function for 15 minutes
--   * the new PIN is 4 digits and not trivial (0000, 1234, 4321, ...)
--
-- It returns a status word instead of raising for the expected failures: an
-- exception would roll back the failed-attempt counter and the lockout would
-- never trigger.
--   ok | wrong_pin | locked | weak_pin | invalid_pin | same_pin | not_allowed

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
  if v_p.id is null or v_p.role <> 'owner' or v_p.account_status <> 'active' then
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
