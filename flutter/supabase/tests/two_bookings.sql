-- A today booking and a postponed tomorrow booking held side by side.
-- Buyer books A today, postpones it, then books B today at another bakery:
-- both rows stand, and today's stock and tomorrow's capacity are right.
-- Run after all migrations; rolls back fixtures.
begin;
reset role;
create function pg_temp.as_buyer(uid uuid) returns void language plpgsql as $$
begin perform set_config('request.jwt.claim.sub', uid::text, true); execute 'set local role authenticated'; end $$;
create function pg_temp.must_fail(stmt text, needle text) returns void language plpgsql as $$
begin execute stmt; raise exception 'unexpected success';
exception when others then
 if sqlerrm = 'unexpected success' or position(needle in sqlerrm) = 0 then raise; end if;
end $$;
insert into auth.users(id) values
 ('b0000000-0000-0000-0000-000000000001'), ('b0000000-0000-0000-0000-000000000002'),
 ('b0000000-0000-0000-0000-000000000003'), ('b0000000-0000-0000-0000-000000000004');
insert into public.profiles(id, phone, pin_hash, name, role) values
 ('b0000000-0000-0000-0000-000000000001', 'tb-owner', 'x', 'Owner', 'owner'),
 ('b0000000-0000-0000-0000-000000000002', 'tb-buyer', 'x', 'Buyer', 'buyer'),
 ('b0000000-0000-0000-0000-000000000003', 'tb-second', 'x', 'Second', 'buyer'),
 ('b0000000-0000-0000-0000-000000000004', 'tb-third', 'x', 'Third', 'buyer');
insert into public.stores(id, name, owner_id, status, is_open, daily_bag_limit, bags_remaining, batch_size) values
 ('b1000000-0000-0000-0000-000000000001', 'Bakery A', 'b0000000-0000-0000-0000-000000000001', 'active', true, 2, 2, 1),
 ('b1000000-0000-0000-0000-000000000002', 'Bakery B', 'b0000000-0000-0000-0000-000000000001', 'active', true, 2, 2, 1);

select pg_temp.as_buyer('b0000000-0000-0000-0000-000000000002');
do $$ declare
 v_today date := (now() at time zone 'Asia/Hebron')::date;
 a public.purchases; b public.purchases; again public.purchases;
begin
 a := public.reserve_bag('b1000000-0000-0000-0000-000000000001', v_today);
 a := public.postpone_purchase(a.id);
 b := public.reserve_bag('b1000000-0000-0000-0000-000000000002', v_today);
 if a.id = b.id then raise exception 'B reused A''s row'; end if;
 if a.purchase_date <> v_today + 1 or a.original_purchase_date <> v_today
    or a.postponement_count <> 1 or a.status <> 'waiting'
    or a.store_id <> 'b1000000-0000-0000-0000-000000000001' then
  raise exception 'A is wrong: %', row_to_json(a); end if;
 if b.purchase_date <> v_today or b.postponement_count <> 0 or b.status <> 'waiting'
    or b.store_id <> 'b1000000-0000-0000-0000-000000000002' then
  raise exception 'B is wrong: %', row_to_json(b); end if;
 -- A retry of B hands B back; it books nothing more.
 again := public.reserve_bag('b1000000-0000-0000-0000-000000000002', v_today);
 if again.id <> b.id then raise exception 'reserve_bag retry made a new row'; end if;
end $$;
-- Still one booking per person per day.
select pg_temp.must_fail($q$select public.reserve_bag('b1000000-0000-0000-0000-000000000001',(now() at time zone 'Asia/Hebron')::date)$q$, 'already reserved a bag today');
select pg_temp.must_fail($q$select public.postpone_purchase(id) from public.purchases
 where user_id = 'b0000000-0000-0000-0000-000000000002' and purchase_date = (now() at time zone 'Asia/Hebron')::date$q$, 'already reserved a bag tomorrow');
reset role;
do $$ declare v_today date := (now() at time zone 'Asia/Hebron')::date; begin
 if (select count(*) from public.purchases where user_id = 'b0000000-0000-0000-0000-000000000002') <> 2 then
  raise exception 'expected exactly two bookings'; end if;
 -- A's bag went back to Bakery A's stock; B took one of Bakery B's.
 if (select bags_remaining from public.stores where id = 'b1000000-0000-0000-0000-000000000001') <> 2 then
  raise exception 'Bakery A stock wrong: %', (select bags_remaining from public.stores where id = 'b1000000-0000-0000-0000-000000000001'); end if;
 if (select bags_remaining from public.stores where id = 'b1000000-0000-0000-0000-000000000002') <> 1 then
  raise exception 'Bakery B stock wrong: %', (select bags_remaining from public.stores where id = 'b1000000-0000-0000-0000-000000000002'); end if;
 if (select count(*) from public.purchases
     where store_id = 'b1000000-0000-0000-0000-000000000001' and purchase_date = v_today + 1) <> 1 then
  raise exception 'Bakery A tomorrow count wrong'; end if;
end $$;
-- A consumed one of Bakery A's two tomorrow places: one more fits, then none.
select pg_temp.as_buyer('b0000000-0000-0000-0000-000000000003');
select public.postpone_purchase((public.reserve_bag('b1000000-0000-0000-0000-000000000001',(now() at time zone 'Asia/Hebron')::date)).id);
reset role;
select pg_temp.as_buyer('b0000000-0000-0000-0000-000000000004');
select pg_temp.must_fail($q$select public.postpone_purchase((public.reserve_bag('b1000000-0000-0000-0000-000000000001',(now() at time zone 'Asia/Hebron')::date)).id)$q$, 'capacity');
reset role;
rollback;
