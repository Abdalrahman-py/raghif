-- The demo world now lives here instead of in the app's drift database.
-- Previously every install seeded its own stores, buyers and queue locally,
-- which is why a receipt could say "batch 4" while Postgres said batch 1:
-- the two datasets were unrelated. Service-role only, invoked by the
-- `seed-demo` Edge Function action.
--
-- Superseded by 20260921141435, which also backfills stores that already
-- exist; this version only inserts missing ones.

create or replace function public.seed_demo_stores()
returns int
language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
  v_created int := 0;
  r record;
begin
  -- The pilot store belongs to the demo owner; the rest are browse-only, so
  -- they carry no owner rather than inventing auth users for them.
  select id into v_owner from public.profiles where national_id = '900333444';

  for r in
    select * from (values
      ('مخبز الرمال',   'الرمال',       true,  300, '08:00'::time, '10:00'::time),
      ('مخبز الشاطئ',   'الشاطئ',       true,  300, '07:30'::time, '09:30'::time),
      ('مخبز النصيرات', 'النصيرات',     false, 300, null::time,    null::time),
      ('مخبز الأمل',    'تل الهوا',     true,  300, '07:00'::time, '09:00'::time),
      ('مخبز الزيتون',  'الزيتون',      true,  300, '07:30'::time, '09:30'::time),
      ('مخبز النور',    'الشيخ رضوان',  true,  300, '06:30'::time, '08:30'::time),
      ('مخبز السلام',   'جباليا',       true,  300, '08:00'::time, '10:00'::time)
    ) as t(name, area, is_open, daily_bag_limit, open_time, close_time)
  loop
    if not exists (select 1 from public.stores s where s.name = r.name) then
      insert into public.stores
        (name, area, is_open, daily_bag_limit, bags_remaining, open_time, close_time,
         batch_size, owner_id)
      values
        (r.name, r.area, r.is_open, r.daily_bag_limit, r.daily_bag_limit,
         r.open_time, r.close_time, 3,
         case when r.name = 'مخبز الرمال' then v_owner else null end);
      v_created := v_created + 1;
    end if;
  end loop;

  return v_created;
end; $$;

-- Lays down one believable day at the pilot store: three batches of three
-- spanning collected / notified / waiting. Idempotent per date, so calling
-- it again the same day is a no-op and a later day stacks on top (the
-- owner's history screen needs earlier days to survive).
--
-- The live demo buyer (900111222) is deliberately excluded: the
-- one-bag-per-national-id-per-day rule would otherwise block a live demo.
create or replace function public.seed_demo_day(p_date date default current_date)
returns int
language plpgsql security definer set search_path = public as $$
declare
  v_store uuid;
  v_seeded int := 0;
  v_i int := 0;
  r record;
  v_status text;
begin
  select id into v_store from public.stores where name = 'مخبز الرمال';
  if v_store is null then return 0; end if;

  if exists (select 1 from public.purchases where store_id = v_store and purchase_date = p_date)
  then return 0; end if;

  for r in
    select id from public.profiles
     where national_id in ('900111333','900111444','900111555','900111666',
                           '900111777','900111888','900111999','900222111','900222222')
     order by national_id
  loop
    v_i := v_i + 1;
    v_status := case
      when v_i <= 3 then 'collected'
      when v_i <= 6 then 'notified'
      else 'waiting' end;

    -- batch_size is 3 at this store, so queue position maps 1:1 onto batches.
    insert into public.purchases
      (store_id, user_id, purchase_date, batch_number, status, created_at)
    values
      (v_store, r.id, p_date, ((v_i - 1) / 3) + 1, v_status,
       now() - make_interval(mins => (20 - v_i)))
    on conflict (user_id, purchase_date) do nothing;

    v_seeded := v_seeded + 1;
  end loop;

  update public.stores
     set bags_remaining = greatest(daily_bag_limit - v_seeded, 0)
   where id = v_store;

  return v_seeded;
end; $$;

revoke execute on function public.seed_demo_stores() from public, anon, authenticated;
revoke execute on function public.seed_demo_day(date) from public, anon, authenticated;
