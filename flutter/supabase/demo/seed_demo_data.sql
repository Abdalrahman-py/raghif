-- Demo data for trying the whole app as if it were live. NOT a migration:
-- nothing runs this automatically, and `supabase db push` ignores this folder.
--
-- Adds, in one transaction:
--   * 15 bakeries: 3 in each of the 5 governorates (a mix of open, sold out,
--     closed and paused ones),
--   * 5 bakery-owner accounts (one per governorate, each managing that
--     governorate's first demo bakery),
--   * 100 buyer accounts (verified; the phone is the Jawwal Pay number),
--   * about a week of bookings (today and the 6 days before, Asia/Hebron),
--     with payments, pinned bakeries and today's notifications.
--
-- Every demo row has an id of the form  de[012]00000-0000-4000-8000-...,
-- so demo/cleanup_demo_data.sql removes exactly these rows and nothing else.
--
-- Sign-in (phone number + PIN):
--   buyers  0569000001 ... 0569000100   PIN 2580
--   owners  0568000001 ... 0568000005   PIN 2580
--     0568000001 شمال غزة · 0568000002 غزة · 0568000003 الوسطى
--     0568000004 خانيونس · 0568000005 رفح
--
-- Push notifications are not sent for demo rows: the triggers that call the
-- push function are switched off for the length of this transaction.

begin;

do $$
begin
  if exists (select 1 from public.profiles where id::text ~ '^de1[0-9a-f]{5}-0000-4000-8000-') then
    raise exception 'demo data is already present; run cleanup_demo_data.sql first';
  end if;
  if exists (select 1 from public.profiles where phone ~ '^056[89][0-9]{6}$') then
    raise exception 'a real account uses a 0568/0569 phone number; pick other demo numbers';
  end if;
end $$;

alter table public.purchases disable trigger notify_purchase_after_insert;
alter table public.purchases disable trigger purchase_inbox_event;
alter table public.purchases disable trigger notify_batch_after_update;
alter table public.notification_inbox disable trigger notification_inbox_push;

select setseed(0.42);

-- ---------------------------------------------------------------- bakeries
create temp table _demo_stores on commit drop as
select n,
       ('de000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid as id,
       governorate, area, name
from (values
  (1,  'شمال غزة', 'جباليا',      'مخبز السنابل'),
  (2,  'شمال غزة', 'بيت لاهيا',   'مخبز البركة'),
  (3,  'شمال غزة', 'بيت حانون',   'مخبز الفجر'),
  (4,  'غزة',      'الرمال',      'مخبز الياسمين'),
  (5,  'غزة',      'الزيتون',     'مخبز الريان'),
  (6,  'غزة',      'الشجاعية',    'مخبز التوفيق'),
  (7,  'الوسطى',   'دير البلح',   'مخبز الصباح'),
  (8,  'الوسطى',   'النصيرات',    'مخبز الخير'),
  (9,  'الوسطى',   'البريج',      'مخبز الهناء'),
  (10, 'خانيونس',  'خانيونس',     'مخبز الواحة'),
  (11, 'خانيونس',  'القرارة',     'مخبز النخيل'),
  (12, 'خانيونس',  'معن',         'مخبز الكرم'),
  (13, 'رفح',      'حي السلام',   'مخبز الأقصى'),
  (14, 'رفح',      'الشابورة',    'مخبز الشروق'),
  (15, 'رفح',      'تل السلطان',  'مخبز الجود')
) as t(n, governorate, area, name);

-- ------------------------------------------------------------------- users
create temp table _demo_users on commit drop as
select n,
       ('de100000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid as id,
       case when n <= 100 then '0569' || lpad(n::text, 6, '0')
            else '0568' || lpad((n - 100)::text, 6, '0') end as phone,
       case when n <= 100 then
              (array['محمد','أحمد','محمود','يوسف','إبراهيم','عمر','خالد','علي','حسن','سامر',
                     'فاطمة','مريم','سارة','ليلى','هدى','آمنة','نور','رنا','سلمى','دعاء'])[1 + (n - 1) % 20]
              || ' ' ||
              (array['الخطيب','النجار','المصري','حمدان','أبو شمالة','الأغا','عبد الله','سلامة','البرغوثي','شعث'])[1 + ((n - 1) / 20 + n) % 10]
            else 'صاحب مخبز ' || (array['شمال غزة','غزة','الوسطى','خانيونس','رفح'])[n - 100]
       end as name,
       case when n <= 100 then 'buyer' else 'owner' end as role
from generate_series(1, 105) as n;

insert into auth.users
  (instance_id, id, aud, role, email, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
-- instance_id: without it the auth server cannot find the user by email and the
-- gateway cannot open a session for the account.
select '00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated',
       'u-' || id || '@raghif.internal', now(),
       '{"provider":"email","providers":["email"]}'::jsonb,
       '{}'::jsonb,
       now() - interval '30 days', now()
from _demo_users;

insert into public.profiles
  (id, phone, pin_hash, name, role, verification_status,
   account_status, created_at, updated_at)
select id, phone, extensions.crypt('2580', extensions.gen_salt('bf', 6)),
       name, role, 'verified', 'active',
       now() - ((10 + n % 20) || ' days')::interval, now()
from _demo_users;

-- --------------------------------------------------------------- store rows
insert into public.stores
  (id, name, owner_id, is_open, daily_bag_limit, bags_remaining, open_time, close_time,
   batch_size, area, governorate, bag_price, status)
select s.id, s.name,
       case when s.n % 3 = 1 then
         ('de100000-0000-4000-8000-' || lpad((100 + (s.n - 1) / 3 + 1)::text, 12, '0'))::uuid
       end,
       s.n not in (4, 11),            -- 2 bakeries are closed today
       100, 100,
       time '06:00', time '14:00',
       20, s.area, s.governorate, 3,
       case when s.n = 9 then 'paused' else 'active' end
from _demo_stores s;

-- ---------------------------------------------------------------- bookings
create temp table _demo_purchases on commit drop as
with today as (select (now() at time zone 'Asia/Hebron')::date as d),
cand as (
  select u.id as user_id, u.n as user_n, g.d as purchase_date,
         1 + floor(random() * 15)::int as store_n,
         random() as r_in, random() as r_status,
         (g.d::timestamp + time '05:30' + random() * interval '5 hours')
           at time zone 'Asia/Hebron' as created_at,
         g.d = (select d from today) as is_today
  from _demo_users u
  cross join (select generate_series((select d from today) - 6, (select d from today), interval '1 day')::date as d) g
  where u.n <= 100
),
chosen as (
  select * from cand where r_in < case when is_today then 0.55 else 0.70 end
),
numbered as (
  select c.*, s.id as store_id,
         row_number() over (partition by c.store_n, c.purchase_date order by c.created_at) as pos,
         row_number() over (order by c.purchase_date, c.created_at, c.user_id) as rn
  from chosen c join _demo_stores s on s.n = c.store_n
)
select ('de200000-0000-4000-8000-' || lpad(rn::text, 12, '0'))::uuid as id,
       store_id, store_n, user_id, purchase_date, created_at, is_today,
       ((pos - 1) / 20 + 1)::int as batch_number,
       case
         when not is_today then case when r_status < 0.90 then 'collected' else 'waiting' end
         when r_status < 0.35 then 'collected'
         when r_status < 0.60 then 'notified'
         else 'waiting'
       end as status
from numbered;

insert into public.purchases
  (id, store_id, user_id, purchase_date, batch_number, status, created_at, updated_at,
   postponement_count)
select id, store_id, user_id, purchase_date, batch_number, status, created_at, created_at, 0
from _demo_purchases;

-- 3 in 4 pay with the (simulated) wallet, the rest in cash at pickup.
insert into public.payments
  (purchase_id, store_id, user_id, amount, method, status, provider, created_at)
select id, store_id, user_id, 3,
       case when abs(hashtext(id::text)) % 4 < 3 then 'jawwal_pay' else 'cash' end,
       'paid',
       case when abs(hashtext(id::text)) % 4 < 3 then 'simulated' end,
       created_at
from _demo_purchases;

-- Stock: today's standing capacity covers the busiest day; sold-out bakeries
-- (every 5th) have nothing left, the others keep a comfortable margin.
update public.stores st
   set daily_bag_limit = case when st.id in (select id from _demo_stores where n % 5 = 0)
                              then greatest(t.cnt, 1)
                              else greatest(100, t.maxday + 20) end,
       bags_remaining  = case when st.id in (select id from _demo_stores where n % 5 = 0)
                              then 0
                              else greatest(100, t.maxday + 20) - t.cnt end
  from (
    select s.id,
           coalesce((select count(*) from _demo_purchases p
                      where p.store_id = s.id and p.is_today), 0) as cnt,
           coalesce((select max(c) from (select count(*) c from _demo_purchases p
                      where p.store_id = s.id group by p.purchase_date) x), 0) as maxday
    from _demo_stores s
  ) t
 where st.id = t.id;

-- ------------------------------------------------- pinned bakeries, inbox
insert into public.store_pins (user_id, store_id)
select u.id, s.id
from _demo_users u
join _demo_stores s on s.n = 1 + (u.n * 7) % 15
where u.n <= 100 and u.n % 3 = 0;

insert into public.notification_inbox (user_id, purchase_id, kind, title, body, created_at)
select p.user_id, p.id, 'confirmed', 'تم تأكيد حجزك',
       format('حجزت رغيفك من %s ليوم %s. سنخبرك فور أن يحين دورك.',
              s.name, to_char(p.purchase_date, 'DD/MM/YYYY')),
       p.created_at
from _demo_purchases p join public.stores s on s.id = p.store_id
where p.is_today;

insert into public.notification_inbox (user_id, purchase_id, kind, title, body, created_at)
select p.user_id, p.id, 'ready', 'حان دورك، تفضّل بالاستلام',
       format('رغيفك جاهز في %s. افتح الحجز وأظهر رمز الاستلام للمخبز.', s.name),
       p.created_at + interval '40 minutes'
from _demo_purchases p join public.stores s on s.id = p.store_id
where p.is_today and p.status in ('notified', 'collected');

alter table public.purchases enable trigger notify_purchase_after_insert;
alter table public.purchases enable trigger purchase_inbox_event;
alter table public.purchases enable trigger notify_batch_after_update;
alter table public.notification_inbox enable trigger notification_inbox_push;

commit;
