-- Admin panel, step 2: everything the panel reads and writes.
--
-- Every function is security definer, pins search_path to '' and starts with
-- the same guard: is_admin() or it raises 'not authorized'. The panel signs in
-- as a normal Supabase user and calls these with the publishable key; nothing
-- else can reach them.
--
-- "Today" is the Asia/Hebron server date, like the queue RPCs.
--
-- Revenue is an estimate: collected bags x stores.bag_price. There is no real
-- payment ledger yet.

-- ------------------------------------------------------------ statistics --

create or replace function public.admin_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Asia/Hebron')::date;
  v_day_start timestamptz := v_today::timestamp at time zone 'Asia/Hebron';
  r jsonb;
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;

  select jsonb_build_object(
    'buyers_total',        count(*) filter (where role = 'buyer'),
    'buyers_new_today',    count(*) filter (where role = 'buyer' and created_at >= v_day_start),
    'buyers_new_week',     count(*) filter (where role = 'buyer' and created_at >= v_day_start - interval '6 days'),
    'buyers_new_month',    count(*) filter (where role = 'buyer' and created_at >= v_day_start - interval '29 days'),
    'buyers_disabled',     count(*) filter (where role = 'buyer' and account_status = 'disabled'),
    'buyers_verified',     count(*) filter (where role = 'buyer' and verification_status = 'verified'),
    'buyers_pending',      count(*) filter (where role = 'buyer' and verification_status = 'pending'),
    'owners_total',        count(*) filter (where role = 'owner')
  ) into r from public.profiles;

  r := r || (
    select jsonb_build_object(
      'stores_total',    count(*),
      'stores_active',   count(*) filter (where status = 'active'),
      'stores_paused',   count(*) filter (where status = 'paused'),
      'stores_archived', count(*) filter (where status = 'archived')
    ) from public.stores
  );

  r := r || (
    select jsonb_build_object(
      'bookings_today',          count(*) filter (where purchase_date = v_today),
      'collected_today',         count(*) filter (where purchase_date = v_today and status = 'collected'),
      'not_collected_today',     count(*) filter (where purchase_date = v_today and status <> 'collected'),
      'bags_sold_total',         count(*),
      'bags_collected_total',    count(*) filter (where status = 'collected')
    ) from public.purchases
  );

  r := r || jsonb_build_object(
    'revenue_estimate_total',
    coalesce((
      select sum(s.bag_price)
        from public.purchases p
        join public.stores s on s.id = p.store_id
       where p.status = 'collected'
    ), 0),
    'revenue_estimate_today',
    coalesce((
      select sum(s.bag_price)
        from public.purchases p
        join public.stores s on s.id = p.store_id
       where p.status = 'collected' and p.purchase_date = v_today
    ), 0)
  );

  return r;
end;
$$;

-- One row per day, zero-filled, oldest first: the booking chart.
create or replace function public.admin_daily_series(p_days int default 30)
returns table (day date, bookings int, collected int, new_buyers int)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Asia/Hebron')::date;
  v_days int := least(greatest(coalesce(p_days, 30), 1), 366);
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  return query
  select d::date,
         coalesce(b.bookings, 0)::int,
         coalesce(b.collected, 0)::int,
         coalesce(n.new_buyers, 0)::int
    from generate_series(v_today - (v_days - 1), v_today, interval '1 day') d
    left join (
      select purchase_date,
             count(*) as bookings,
             count(*) filter (where status = 'collected') as collected
        from public.purchases
       group by purchase_date
    ) b on b.purchase_date = d::date
    left join (
      select (created_at at time zone 'Asia/Hebron')::date as day,
             count(*) as new_buyers
        from public.profiles
       where role = 'buyer'
       group by 1
    ) n on n.day = d::date
   order by d;
end;
$$;

-- Scan outcomes over the last [p_days] days.
create or replace function public.admin_scan_summary(p_days int default 30)
returns table (outcome text, total bigint)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  return query
  select e.outcome, count(*)
    from public.scan_events e
   where e.scanned_at >= now() - make_interval(days => least(greatest(coalesce(p_days, 30), 1), 366))
   group by e.outcome
   order by 2 desc;
end;
$$;

-- Inbox and device numbers, for the notifications page.
create or replace function public.admin_notification_stats(p_days int default 30)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_since timestamptz := now() - make_interval(days => least(greatest(coalesce(p_days, 30), 1), 366));
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  return jsonb_build_object(
    'inbox_total',  (select count(*) from public.notification_inbox where created_at >= v_since),
    'inbox_unread', (select count(*) from public.notification_inbox where created_at >= v_since and read_at is null),
    'by_kind', coalesce((
      select jsonb_agg(jsonb_build_object('kind', kind, 'total', total) order by total desc)
        from (
          select kind, count(*) as total
            from public.notification_inbox
           where created_at >= v_since
           group by kind
        ) k
    ), '[]'::jsonb),
    'devices_registered', (select count(*) from public.device_tokens),
    'users_with_device',  (select count(distinct user_id) from public.device_tokens)
  );
end;
$$;

-- ----------------------------------------------------------------- lists --

-- Bakeries with their owner and numbers. [p_idle_days] only feeds the `idle`
-- flag (no booking for that many days, or never).
create or replace function public.admin_list_stores(p_idle_days int default 7)
returns table (
  store_id uuid,
  name text,
  status text,
  is_open boolean,
  area text,
  governorate text,
  bag_price numeric,
  daily_bag_limit int,
  bags_remaining int,
  batch_size int,
  open_time time,
  close_time time,
  owner_id uuid,
  owner_name text,
  owner_phone text,
  owner_account_status text,
  total_bookings bigint,
  collected bigint,
  collect_rate numeric,
  bookings_today bigint,
  last_booking_date date,
  idle boolean,
  revenue_estimate numeric,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Asia/Hebron')::date;
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  return query
  select s.id, s.name, s.status, s.is_open, s.area, s.governorate, s.bag_price,
         s.daily_bag_limit, s.bags_remaining, s.batch_size, s.open_time, s.close_time,
         s.owner_id, o.name, o.phone, o.account_status,
         coalesce(a.total, 0), coalesce(a.collected, 0),
         case when coalesce(a.total, 0) = 0 then 0
              else round(a.collected::numeric / a.total, 4) end,
         coalesce(a.today, 0),
         a.last_date,
         (a.last_date is null or a.last_date < v_today - greatest(coalesce(p_idle_days, 7), 1)),
         coalesce(a.collected, 0) * s.bag_price,
         s.created_at
    from public.stores s
    left join public.profiles o on o.id = s.owner_id
    left join (
      -- qualified: store_id and status are also this function's output names
      select pu.store_id as sid,
             count(*) as total,
             count(*) filter (where pu.status = 'collected') as collected,
             count(*) filter (where pu.purchase_date = v_today) as today,
             max(pu.purchase_date) as last_date
        from public.purchases pu
       group by pu.store_id
    ) a on a.sid = s.id
   order by coalesce(a.total, 0) desc, s.created_at;
end;
$$;

-- Buyers, newest first. [p_search] matches name, phone or national id.
-- `missed` counts past bookings that were never collected.
create or replace function public.admin_list_buyers(
  p_search text default null,
  p_limit int default 50,
  p_offset int default 0
)
returns table (
  id uuid,
  name text,
  phone text,
  national_id text,
  verification_status text,
  account_status text,
  created_at timestamptz,
  bookings bigint,
  collected bigint,
  missed bigint,
  total_matches bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Asia/Hebron')::date;
  v_q text := nullif(btrim(coalesce(p_search, '')), '');
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  return query
  select p.id, p.name, p.phone, p.national_id, p.verification_status,
         p.account_status, p.created_at,
         coalesce(a.bookings, 0), coalesce(a.collected, 0), coalesce(a.missed, 0),
         count(*) over ()
    from public.profiles p
    left join (
      select user_id,
             count(*) as bookings,
             count(*) filter (where status = 'collected') as collected,
             count(*) filter (where status <> 'collected' and purchase_date < v_today) as missed
        from public.purchases
       group by user_id
    ) a on a.user_id = p.id
   where p.role = 'buyer'
     and (v_q is null
          or p.name ilike '%' || v_q || '%'
          or p.phone ilike '%' || v_q || '%'
          or p.national_id ilike '%' || v_q || '%')
   order by p.created_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

-- ------------------------------------------------------------- mutations --

create or replace function public.admin_set_store_status(p_store uuid, p_status text)
returns public.stores
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_store public.stores;
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  if p_status not in ('active', 'paused', 'archived') then
    raise exception 'invalid status';
  end if;
  update public.stores set status = p_status where id = p_store
  returning * into v_store;
  if v_store.id is null then raise exception 'store not found'; end if;
  return v_store;
end;
$$;

-- Edits a bakery. Null leaves a field unchanged. A new daily limit follows
-- the same rules as the owner's own save: stock for today is recomputed, and
-- the limit may not drop below what is already booked for tomorrow.
create or replace function public.admin_update_store(
  p_store uuid,
  p_name text default null,
  p_area text default null,
  p_governorate text default null,
  p_daily_bag_limit int default null,
  p_bag_price numeric default null,
  p_batch_size int default null,
  p_open_time time default null,
  p_close_time time default null
)
returns public.stores
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Asia/Hebron')::date;
  v_store public.stores;
  v_sold int;
  v_future int;
  v_limit int;
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;

  -- stores row first, then purchases: the queue's lock order.
  select * into v_store from public.stores where id = p_store for update;
  if v_store.id is null then raise exception 'store not found'; end if;

  v_limit := coalesce(p_daily_bag_limit, v_store.daily_bag_limit);
  if v_limit < 0 then raise exception 'daily limit cannot be negative'; end if;
  if p_bag_price is not null and p_bag_price < 0 then
    raise exception 'price cannot be negative';
  end if;

  select count(*) into v_future from public.purchases
   where store_id = p_store and purchase_date = v_today + 1;
  if v_limit < v_future then
    raise exception 'allocation below existing future bookings';
  end if;
  select count(*) into v_sold from public.purchases
   where store_id = p_store and purchase_date = v_today;

  update public.stores set
    name = coalesce(nullif(btrim(p_name), ''), name),
    area = coalesce(p_area, area),
    governorate = coalesce(p_governorate, governorate),
    daily_bag_limit = v_limit,
    bags_remaining = greatest(v_limit - v_sold, 0),
    bag_price = coalesce(p_bag_price, bag_price),
    batch_size = greatest(coalesce(p_batch_size, batch_size), 1),
    open_time = coalesce(p_open_time, open_time),
    close_time = coalesce(p_close_time, close_time)
  where id = p_store
  returning * into v_store;
  return v_store;
end;
$$;

create or replace function public.admin_set_buyer_status(p_user uuid, p_status text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  if p_status not in ('active', 'disabled') then
    raise exception 'invalid status';
  end if;
  if exists (select 1 from public.admins where user_id = p_user) then
    raise exception 'an administrator cannot be disabled here';
  end if;
  update public.profiles set account_status = p_status where id = p_user
  returning * into v_profile;
  if v_profile.id is null then raise exception 'user not found'; end if;
  -- never hand the PIN hash to a browser
  return jsonb_build_object(
    'id', v_profile.id, 'name', v_profile.name, 'phone', v_profile.phone,
    'verification_status', v_profile.verification_status,
    'account_status', v_profile.account_status);
end;
$$;

create or replace function public.admin_set_verification(p_user uuid, p_status text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  if p_status not in ('pending', 'verified') then
    raise exception 'invalid status';
  end if;
  update public.profiles set verification_status = p_status where id = p_user
  returning * into v_profile;
  if v_profile.id is null then raise exception 'user not found'; end if;
  -- never hand the PIN hash to a browser
  return jsonb_build_object(
    'id', v_profile.id, 'name', v_profile.name, 'phone', v_profile.phone,
    'verification_status', v_profile.verification_status,
    'account_status', v_profile.account_status);
end;
$$;

-- Creates the store half of a new bakery. The owner's auth user and profile
-- already exist (the admin-api edge function makes them with the service key
-- and then calls this). Service role only.
create or replace function public.admin_create_store_for(
  p_owner uuid,
  p_name text,
  p_area text,
  p_governorate text,
  p_daily_bag_limit int default 100,
  p_bag_price numeric default 3,
  p_batch_size int default 10
)
returns public.stores
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_store public.stores;
begin
  if not exists (select 1 from public.profiles where id = p_owner and role = 'owner') then
    raise exception 'owner profile not found';
  end if;
  if exists (select 1 from public.stores where owner_id = p_owner) then
    raise exception 'owner already has a store';
  end if;
  insert into public.stores
    (name, owner_id, area, governorate, daily_bag_limit, bags_remaining,
     bag_price, batch_size, is_open, status)
  values
    (btrim(p_name), p_owner, p_area, p_governorate,
     greatest(p_daily_bag_limit, 0), greatest(p_daily_bag_limit, 0),
     p_bag_price, greatest(p_batch_size, 1), false, 'active')
  returning * into v_store;
  return v_store;
end;
$$;

-- ---------------------------------------------------------------- grants --

do $$
declare
  f text;
begin
  -- Callable by a signed-in user (the guard inside decides) and the service.
  foreach f in array array[
    'admin_overview()',
    'admin_daily_series(int)',
    'admin_scan_summary(int)',
    'admin_notification_stats(int)',
    'admin_list_stores(int)',
    'admin_list_buyers(text, int, int)',
    'admin_set_store_status(uuid, text)',
    'admin_update_store(uuid, text, text, text, int, numeric, int, time, time)',
    'admin_set_buyer_status(uuid, text)',
    'admin_set_verification(uuid, text)'
  ] loop
    execute format('revoke execute on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to authenticated, service_role', f);
  end loop;

  -- Service role only: no is_admin() guard inside, the edge function checks.
  revoke execute on function public.admin_create_store_for(uuid, text, text, text, int, numeric, int)
    from public, anon, authenticated;
  grant execute on function public.admin_create_store_for(uuid, text, text, text, int, numeric, int)
    to service_role;
end $$;
