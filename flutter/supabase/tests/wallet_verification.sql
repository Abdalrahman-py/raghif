-- Rollback-only checks for verify_my_wallet and the wallet-change reset.
begin;
insert into auth.users(id) values
 ('f1000000-0000-0000-0000-000000000001'),
 ('f1000000-0000-0000-0000-000000000002');
insert into public.profiles(id, name, phone, national_id, pin_hash, role, verification_status) values
 ('f1000000-0000-0000-0000-000000000001','Buyer','0599777701','wv-test-1','x','buyer','pending'),
 ('f1000000-0000-0000-0000-000000000002','Owner','0599777702','wv-test-2','x','owner','verified');

do $$ begin
  -- Direct writes are closed.
  if has_column_privilege('authenticated','public.profiles','verification_status','UPDATE')
     or has_column_privilege('authenticated','public.profiles','jawwal_pay_number','UPDATE') then
    raise exception 'client can still write verification columns';
  end if;
  if has_function_privilege('anon','public.verify_my_wallet(text,text)','EXECUTE') then
    raise exception 'anon can call verify_my_wallet';
  end if;
end $$;

set local role authenticated;
select set_config('request.jwt.claim.sub','f1000000-0000-0000-0000-000000000001',true);
do $$ begin
  if public.verify_my_wallet('0599111111','0000') <> 'wrong_code' then raise exception 'wrong code accepted'; end if;
  if public.verify_my_wallet('123','1234') <> 'invalid_number' then raise exception 'bad number accepted'; end if;
  if (select verification_status from public.profiles where id = 'f1000000-0000-0000-0000-000000000001') <> 'pending' then
    raise exception 'verified without a valid code';
  end if;
  if public.verify_my_wallet(' 0599111111 ','1234') <> 'ok' then raise exception 'good code refused'; end if;
  if not exists (select 1 from public.profiles where id = 'f1000000-0000-0000-0000-000000000001'
                   and verification_status = 'verified' and jawwal_pay_number = '0599111111') then
    raise exception 'not verified after ok';
  end if;
  -- Same number, new name: stays verified.
  perform public.update_my_profile('Buyer Two','0599777701','0599111111');
  if (select verification_status from public.profiles where id = 'f1000000-0000-0000-0000-000000000001') <> 'verified' then
    raise exception 'same wallet number lost verification';
  end if;
  -- Another number: back to pending.
  perform public.update_my_profile('Buyer Two','0599777701','0599222222');
  if (select verification_status from public.profiles where id = 'f1000000-0000-0000-0000-000000000001') <> 'pending' then
    raise exception 'new wallet number stayed verified';
  end if;
end $$;

-- An owner is not a buyer: no self-verification path, and no downgrade.
select set_config('request.jwt.claim.sub','f1000000-0000-0000-0000-000000000002',true);
do $$ begin
  if public.verify_my_wallet('0599333333','1234') <> 'not_allowed' then raise exception 'owner verified through wallet'; end if;
  perform public.update_my_profile('Owner','0599777702','0599333333');
  if (select verification_status from public.profiles where id = 'f1000000-0000-0000-0000-000000000002') <> 'verified' then
    raise exception 'owner lost verification';
  end if;
end $$;

select set_config('request.jwt.claim.sub','',true);
do $$ begin
  begin
    perform public.verify_my_wallet('0599111111','1234');
    raise exception 'unauthenticated call succeeded';
  exception when sqlstate '42501' then null; end;
end $$;
rollback;
