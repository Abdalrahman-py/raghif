-- Closes the gaps left by 20260921141305: the RPCs existed, but the tables
-- still accepted the same writes directly, and a few RPCs trusted the client.
--
-- 1. Every write to purchases / scan_events now goes through an RPC. The
--    direct insert/update policies are dropped, so `reserve_bag` (batch
--    number, sold-out, one-bag-a-day) can no longer be bypassed.
-- 2. profiles: `pin_hash` and `role` are not readable / writable by the app.
--    The owner-visible profile policy used to ship every buyer's bcrypt hash
--    to the owner's phone with a plain `select *`.
-- 3. collect_purchase only collects a notified purchase; record_scan only
--    accepts known outcomes for a purchase of that store.
-- 4. save_store_allocation no longer takes is_open from the client (a stale
--    cache could reopen a closed store) and locks the store row like
--    reserve_bag does, so a reservation cannot slip between the count and
--    the update and leave bags_remaining too high.
-- 5. New RPCs are revoked from anon, matching the earlier hardening.

-- ------------------------------------------------------------ profiles --
revoke select, insert, update on public.profiles from anon, authenticated;
grant select (id, phone, national_id, name, role, jawwal_pay_number,
              verification_status, created_at, updated_at)
  on public.profiles to authenticated;
-- verification_status stays writable: the simulated Jawwal Pay step flips it
-- (constitution VI). role and pin_hash are server-only.
grant update (name, jawwal_pay_number, verification_status)
  on public.profiles to authenticated;
drop policy if exists "profiles_insert_own" on public.profiles;

-- ------------------------------------------------- purchases, scan_events --
drop policy if exists "purchases_insert_own" on public.purchases;
drop policy if exists "purchases_update_store_owner" on public.purchases;

drop policy if exists "scan_events_store_owner_only" on public.scan_events;
create policy "scan_events_store_owner_select" on public.scan_events
  for select using (
    exists (select 1 from public.stores s
             where s.id = scan_events.store_id and s.owner_id = (select auth.uid()))
  );

-- ------------------------------------------------------ collect_purchase --
create or replace function public.collect_purchase(p_purchase_id uuid)
returns public.purchases
language plpgsql security definer set search_path = public as $$
declare v_purchase public.purchases;
begin
  if not exists (
    select 1 from public.purchases p join public.stores s on s.id = p.store_id
     where p.id = p_purchase_id and s.owner_id = (select auth.uid())
  ) then raise exception 'not the store owner' using errcode = 'P0001'; end if;

  update public.purchases set status = 'collected'
   where id = p_purchase_id and status = 'notified' returning * into v_purchase;

  if v_purchase.id is null then
    select * into v_purchase from public.purchases where id = p_purchase_id;
    -- Already collected is a harmless repeat scan; a waiting batch has not
    -- been called yet and must not be handed a bag.
    if v_purchase.status = 'waiting' then
      raise exception 'batch not notified yet' using errcode = 'P0001';
    end if;
  end if;
  return v_purchase;
end; $$;

-- ------------------------------------------------------------ record_scan --
create or replace function public.record_scan(
  p_store_id uuid, p_outcome text, p_purchase_id uuid default null,
  p_scanned_name text default null, p_scanned_national_id text default null)
returns public.scan_events
language plpgsql security definer set search_path = public as $$
declare v_event public.scan_events;
begin
  if not exists (select 1 from public.stores where id = p_store_id and owner_id = (select auth.uid()))
  then raise exception 'not the store owner' using errcode = 'P0001'; end if;

  if p_outcome not in ('checkedIn', 'alreadyCollected', 'batchNotCalledYet',
                       'notFoundHere', 'wrongStore', 'invalidCode') then
    raise exception 'unknown scan outcome' using errcode = 'P0001';
  end if;

  -- A scan of another store's receipt is still logged, but without linking
  -- this store's audit trail to a purchase it does not own.
  if p_purchase_id is not null and not exists (
    select 1 from public.purchases where id = p_purchase_id and store_id = p_store_id
  ) then p_purchase_id := null; end if;

  insert into public.scan_events (store_id, purchase_id, outcome, scanned_name, scanned_national_id)
  values (p_store_id, p_purchase_id, p_outcome, p_scanned_name, p_scanned_national_id)
  returning * into v_event;
  return v_event;
end; $$;

-- ---------------------------------------------------- save_store_allocation --
drop function if exists public.save_store_allocation(uuid, int, boolean, int, date, time, time);

create or replace function public.save_store_allocation(
  p_store_id uuid, p_daily_bag_limit int, p_batch_size int,
  p_purchase_date date, p_open_time time default null, p_close_time time default null)
returns public.stores
language plpgsql security definer set search_path = public as $$
declare v_sold int; v_store public.stores;
begin
  -- Same lock reserve_bag takes: the count below must not race a reservation.
  perform 1 from public.stores
   where id = p_store_id and owner_id = (select auth.uid()) for update;
  if not found then raise exception 'not the store owner' using errcode = 'P0001'; end if;

  select count(*) into v_sold from public.purchases
   where store_id = p_store_id and purchase_date = p_purchase_date;

  update public.stores
     set daily_bag_limit = greatest(p_daily_bag_limit, 0),
         batch_size = greatest(p_batch_size, 1),
         bags_remaining = greatest(p_daily_bag_limit - v_sold, 0),
         open_time = p_open_time, close_time = p_close_time
   where id = p_store_id returning * into v_store;
  return v_store;
end; $$;

-- ---------------------------------------------------------------- grants --
revoke execute on function public.collect_purchase(uuid) from public, anon;
revoke execute on function public.set_store_open(uuid, boolean) from public, anon;
revoke execute on function public.record_scan(uuid, text, uuid, text, text) from public, anon;
revoke execute on function public.set_store_pinned(uuid, boolean) from public, anon;
revoke execute on function public.save_store_allocation(uuid, int, int, date, time, time) from public, anon;
revoke execute on function public.store_customers(uuid) from public, anon;
revoke execute on function public.store_daily_summaries(uuid, int) from public, anon;

grant execute on function public.save_store_allocation(uuid, int, int, date, time, time) to authenticated;
