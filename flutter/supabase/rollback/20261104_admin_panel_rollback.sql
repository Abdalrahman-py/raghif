-- Undoes migrations 20261104100000 .. 20261105130000 (the admin panel schema,
-- sign-in lockout and cash payments).
-- NOT a migration: it lives outside migrations/ on purpose and is run by hand,
-- only if the panel's database changes have to be taken back out.
--
-- What it removes, in reverse order of how it was added:
--   inbox push trigger, service helpers, change_my_pin, announcements,
--   the admin_* functions, status/price/account columns, the admins table,
--   the new stores policies, and it puts back the previous reserve_bag, the
--   public stores policy and DELETE on stores/profiles.
--
-- DATA LOSS you should know about before running it:
--   * every notification_inbox row of kind 'announcement' is deleted (they
--     cannot exist once purchase_id is NOT NULL again);
--   * stores.status, stores.bag_price, profiles.account_status and the PIN
--     lockout counters are dropped with their values. A store that was
--     archived or paused becomes visible and bookable again; a disabled
--     account can sign in again.
--   * the admins table (and so every administrator) is dropped.
-- Bookings, stores, profiles and the transactional inbox rows are untouched.
--
-- Run it in one transaction; it fails closed if anything is missing.
begin;

-- 11. housekeeping (20261105130000): the daily job and its function go. Rows
-- already deleted by it are not restored.
do $$
begin
  if to_regclass('cron.job') is not null then
    perform cron.unschedule(jobid) from cron.job where jobname = 'raghif-housekeeping';
  end if;
end $$;
drop function if exists public.run_housekeeping();

-- 10. support-model hardening (20261105120000): change_my_pin is owners-only
-- again, and update_my_profile may change the phone number again (with the
-- "phone already registered" error).
create or replace function public.change_my_pin(p_old text, p_new text)
returns text
language plpgsql security definer set search_path = ''
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
         set pin_failed_attempts = 0, pin_locked_until = now() + interval '15 minutes'
       where id = v_uid;
      return 'locked';
    end if;
    update public.profiles set pin_failed_attempts = pin_failed_attempts + 1 where id = v_uid;
    return 'wrong_pin';
  end if;
  if p_new is null or p_new !~ '^[0-9]{4}$' then return 'invalid_pin'; end if;
  if p_new = p_old then return 'same_pin'; end if;
  if p_new ~ '^([0-9])\1{3}$'
     or p_new in ('0123', '1234', '2345', '3456', '4567', '5678', '6789',
                  '3210', '4321', '5432', '6543', '7654', '8765', '9876') then
    return 'weak_pin';
  end if;
  update public.profiles
     set pin_hash = extensions.crypt(p_new, extensions.gen_salt('bf')),
         pin_failed_attempts = 0, pin_locked_until = null
   where id = v_uid;
  return 'ok';
end;
$$;
revoke execute on function public.change_my_pin(text, text) from public, anon, authenticated;
grant execute on function public.change_my_pin(text, text) to authenticated;

create or replace function public.update_my_profile(
  p_name text, p_phone text, p_jawwal_pay_number text
)
returns table (
  id uuid, phone text, national_id text, name text, role text,
  jawwal_pay_number text, verification_status text
)
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
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

  update public.profiles p set name = btrim(p_name), phone = btrim(p_phone),
    jawwal_pay_number = nullif(btrim(p_jawwal_pay_number), '')
    where p.id = v_uid;
  if not found then raise exception 'profile not found' using errcode = 'P0001'; end if;
  return query select p.id, p.phone, p.national_id, p.name, p.role,
    p.jawwal_pay_number, p.verification_status from public.profiles p where p.id = v_uid;
exception when unique_violation then
  raise exception 'phone already registered' using errcode = 'P0001';
end;
$$;
revoke all on function public.update_my_profile(text, text, text) from public, anon;
grant execute on function public.update_my_profile(text, text, text) to authenticated;

-- 9. wallet payment record (20261105110000): the function goes; the provider
-- column and the widened method check go with the payments table below.
drop function if exists public.record_wallet_payment(uuid);

-- 8. cash payments (20261105100000): the payments table (and every cash record
-- in it) is dropped, and collect_purchase / store_daily_summaries go back to
-- not knowing about money.
drop function if exists public.store_daily_summaries(uuid, integer);
create function public.store_daily_summaries(p_store_id uuid, p_limit integer default 30)
returns table(purchase_date date, sold bigint, collected bigint, not_collected bigint)
language plpgsql security definer set search_path to 'public'
as $$
begin
  if not exists (select 1 from public.stores where id = p_store_id and owner_id = (select auth.uid()))
  then raise exception 'not the store owner' using errcode = 'P0001'; end if;
  return query
    select p.purchase_date, count(*),
           count(*) filter (where p.status = 'collected'),
           count(*) filter (where p.status <> 'collected')
      from public.purchases p where p.store_id = p_store_id
     group by p.purchase_date order by p.purchase_date desc limit greatest(p_limit, 1);
end; $$;
revoke execute on function public.store_daily_summaries(uuid, integer) from public, anon, authenticated;
grant execute on function public.store_daily_summaries(uuid, integer) to authenticated;

create or replace function public.collect_purchase(p_purchase_id uuid)
returns public.purchases
language plpgsql security definer set search_path to 'public'
as $$
declare v_p public.purchases; v_store_id uuid;
begin
 select store_id into v_store_id from public.purchases where id=p_purchase_id;
 perform 1 from public.stores where id=v_store_id and owner_id=auth.uid() for update;
 if not found then raise exception 'not the store owner'; end if;
 select * into v_p from public.purchases where id=p_purchase_id for update;
 if v_p.purchase_date <> (now() at time zone 'Asia/Hebron')::date then raise exception 'collection is for today only'; end if;
 if v_p.status='waiting' then raise exception 'batch not notified yet'; end if;
 update public.purchases set status='collected' where id=p_purchase_id returning * into v_p;
 return v_p;
end $$;
revoke execute on function public.collect_purchase(uuid) from public, anon, authenticated;
grant execute on function public.collect_purchase(uuid) to authenticated;

drop table if exists public.payments;

-- 7. sign-in lockout (20261104110000): the counters are dropped with their
-- values, so a locked account can sign in again.
drop function if exists public.login_attempt(text, text, text);
alter table public.profiles
  drop column if exists login_failed_attempts,
  drop column if exists login_locked_until;
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

-- 6. inbox push trigger
drop trigger if exists notification_inbox_push on public.notification_inbox;
drop function if exists public.trigger_push_inbox();

-- 5. service helpers
drop function if exists public.admin_revoke_sessions(uuid);
drop function if exists public.admin_set_pin(uuid, text);

-- 4. change_my_pin
drop function if exists public.change_my_pin(text, text);

-- 3. announcements
drop function if exists public.admin_send_notification(text, text, text, uuid);
delete from public.notification_inbox where kind = 'announcement' or purchase_id is null;
alter table public.notification_inbox drop constraint if exists notification_inbox_kind_check;
alter table public.notification_inbox
  add constraint notification_inbox_kind_check
  check (kind in ('confirmed', 'ready', 'postponed'));
alter table public.notification_inbox alter column purchase_id set not null;

-- 2. admin functions
drop function if exists public.admin_overview();
drop function if exists public.admin_daily_series(int);
drop function if exists public.admin_scan_summary(int);
drop function if exists public.admin_notification_stats(int);
drop function if exists public.admin_list_stores(int);
drop function if exists public.admin_list_buyers(text, int, int);
drop function if exists public.admin_set_store_status(uuid, text);
drop function if exists public.admin_update_store(uuid, text, text, text, int, numeric, int, time, time);
drop function if exists public.admin_set_buyer_status(uuid, text);
drop function if exists public.admin_set_verification(uuid, text);
drop function if exists public.admin_create_store_for(uuid, text, text, text, int, numeric, int);

-- 1. foundation, in the order that satisfies dependencies

-- reserve_bag as it was before (today only, stores row locked first).
create or replace function public.reserve_bag(p_store_id uuid,p_purchase_date date)
returns public.purchases language plpgsql security definer set search_path=public as $$
declare v_uid uuid:=auth.uid(); v_store public.stores; v_sold int; v_p public.purchases;
 v_today date := (now() at time zone 'Asia/Hebron')::date;
begin
 if v_uid is null then raise exception 'not authenticated'; end if;
 if p_purchase_date is distinct from v_today then raise exception 'reservations are for today only'; end if;
 select * into v_store from public.stores where id=p_store_id for update;
 select count(*) into v_sold from public.purchases where store_id=p_store_id and purchase_date=v_today;
 if v_store.id is null or not v_store.is_open or v_store.bags_remaining<=0 or v_sold>=v_store.daily_bag_limit then
  raise exception 'store closed or sold out'; end if;
 insert into public.purchases(store_id,user_id,purchase_date,batch_number,status)
 values(p_store_id,v_uid,v_today,v_sold/greatest(v_store.batch_size,1)+1,'waiting') returning * into v_p;
 update public.stores set bags_remaining=greatest(least(bags_remaining-1,daily_bag_limit-v_sold-1),0) where id=p_store_id;
 return v_p;
exception when unique_violation then raise exception 'already reserved a bag today';
end $$;

drop function if exists public.account_login_block(uuid);

-- stores visibility: back to "everyone reads every store".
drop policy if exists stores_select_anon on public.stores;
drop policy if exists stores_select_authenticated on public.stores;
create policy stores_select_public on public.stores for select using (true);
drop function if exists public.user_has_purchase_at(uuid);

-- DELETE as it was (table-level, authenticated only).
grant delete on public.stores, public.profiles to authenticated;

drop trigger if exists stores_guard_admin_columns on public.stores;
drop function if exists public.stores_guard_admin_columns();
drop index if exists public.stores_status_idx;

alter table public.stores drop column if exists status, drop column if exists bag_price;
alter table public.profiles
  drop column if exists account_status,
  drop column if exists pin_failed_attempts,
  drop column if exists pin_locked_until;

drop function if exists public.is_admin();
drop table if exists public.admins;

commit;
