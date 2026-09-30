-- seed_demo_stores() skipped any store that already existed by name, so the
-- pilot store created before this seed kept an empty area and whatever
-- window it was given by hand. Backfill metadata on rows it recognises
-- instead of only inserting missing ones -- the owner's own allocation
-- (limit, open state, bags remaining) is left alone, since that is live data
-- the owner controls, not seed data.
create or replace function public.seed_demo_stores()
returns int
language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
  v_created int := 0;
  r record;
begin
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
    if exists (select 1 from public.stores s where s.name = r.name) then
      update public.stores s
         set area       = case when s.area = '' then r.area else s.area end,
             open_time  = coalesce(s.open_time, r.open_time),
             close_time = coalesce(s.close_time, r.close_time),
             owner_id   = case
                            when r.name = 'مخبز الرمال' then coalesce(s.owner_id, v_owner)
                            else s.owner_id
                          end
       where s.name = r.name;
    else
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

revoke execute on function public.seed_demo_stores() from public, anon, authenticated;
