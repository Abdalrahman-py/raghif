-- Rollback-only checks for verify_my_wallet. The wallet number is the profile's
-- own phone number, so there is nothing to pass or change.
begin;
insert into auth.users(id) values
 ('f1000000-0000-0000-0000-000000000001'),
 ('f1000000-0000-0000-0000-000000000002');
insert into public.profiles(id, name, phone, pin_hash, role, verification_status) values
 ('f1000000-0000-0000-0000-000000000001','Buyer','0599777701','x','buyer','pending'),
 ('f1000000-0000-0000-0000-000000000002','Owner','0599777702','x','owner','verified');

do $$ begin
  -- Direct writes are closed.
  if has_column_privilege('authenticated','public.profiles','verification_status','UPDATE')
     or has_column_privilege('authenticated','public.profiles','phone','UPDATE') then
    raise exception 'client can still write verification columns';
  end if;
  if has_function_privilege('anon','public.verify_my_wallet(text)','EXECUTE') then
    raise exception 'anon can call verify_my_wallet';
  end if;
end $$;

set local role authenticated;
select set_config('request.jwt.claim.sub','f1000000-0000-0000-0000-000000000001',true);
do $$ begin
  if public.verify_my_wallet('0000') <> 'wrong_code' then raise exception 'wrong code accepted'; end if;
  if (select verification_status from public.profiles where id = 'f1000000-0000-0000-0000-000000000001') <> 'pending' then
    raise exception 'verified without a valid code';
  end if;
  if public.verify_my_wallet('1234') <> 'ok' then raise exception 'good code refused'; end if;
  if not exists (select 1 from public.profiles where id = 'f1000000-0000-0000-0000-000000000001'
                   and verification_status = 'verified') then
    raise exception 'not verified after ok';
  end if;
  -- A rename keeps the verification: the number did not change.
  perform public.update_my_profile('Buyer Two');
  if (select verification_status from public.profiles where id = 'f1000000-0000-0000-0000-000000000001') <> 'verified' then
    raise exception 'rename lost verification';
  end if;
end $$;

-- An owner is not a buyer: no self-verification path, and no downgrade.
select set_config('request.jwt.claim.sub','f1000000-0000-0000-0000-000000000002',true);
do $$ begin
  if public.verify_my_wallet('1234') <> 'not_allowed' then raise exception 'owner verified through wallet'; end if;
  perform public.update_my_profile('Owner');
  if (select verification_status from public.profiles where id = 'f1000000-0000-0000-0000-000000000002') <> 'verified' then
    raise exception 'owner lost verification';
  end if;
end $$;

select set_config('request.jwt.claim.sub','',true);
do $$ begin
  begin
    perform public.verify_my_wallet('1234');
    raise exception 'unauthenticated call succeeded';
  exception when sqlstate '42501' then null; end;
end $$;
rollback;
