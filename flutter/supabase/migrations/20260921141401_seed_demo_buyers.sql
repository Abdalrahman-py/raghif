-- Creates the dummy buyers that populate the demo queue.
--
-- profiles.id is FK'd to auth.users, so a profile cannot exist without an
-- auth row. The `seed-demo` Edge Function action does this properly via the
-- admin API; this SQL twin exists so the seed can also be run straight from
-- a migration or psql, without a service-role JWT in hand.
--
-- These rows are deliberately incomplete as auth identities: no
-- auth.identities row and no usable password, so none of them can sign in.
-- That is intended -- they are queue furniture, not accounts. The two real
-- demo logins (900111222 / 900333444) are created through the admin API.
--
-- Service-role only; revoked from anon and authenticated below.
create or replace function public.seed_demo_buyers()
returns int
language plpgsql security definer set search_path = public as $$
declare
  v_created int := 0;
  v_uid uuid;
  r record;
begin
  for r in
    select * from (values
      ('900111333','0599111333','محمود سعيد'),
      ('900111444','0599111444','إبراهيم حمدان'),
      ('900111555','0599111555','سارة عبد الرحمن'),
      ('900111666','0599111666','ليلى المصري'),
      ('900111777','0599111777','عمر الخطيب'),
      ('900111888','0599111888','فاطمة الزهراء'),
      ('900111999','0599111999','يوسف النجار'),
      ('900222111','0599222111','مريم خالد'),
      ('900222222','0599222333','حسن عباس')
    ) as t(national_id, phone, name)
  loop
    if exists (select 1 from public.profiles p where p.national_id = r.national_id)
    then continue; end if;

    v_uid := gen_random_uuid();

    insert into auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous
    ) values (
      v_uid,
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'nid-' || r.national_id || '@raghif.internal',
      '',
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('national_id', r.national_id, 'demo_queue_buyer', true),
      false, false
    );

    insert into public.profiles
      (id, phone, national_id, name, role, verification_status)
    values
      (v_uid, r.phone, r.national_id, r.name, 'buyer', 'verified');

    v_created := v_created + 1;
  end loop;

  return v_created;
end; $$;

revoke execute on function public.seed_demo_buyers() from public, anon, authenticated;
