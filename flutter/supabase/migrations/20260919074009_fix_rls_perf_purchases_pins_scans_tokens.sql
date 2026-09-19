drop policy "purchases_select_own_or_store_owner" on public.purchases;
drop policy "purchases_insert_own" on public.purchases;
drop policy "purchases_update_store_owner" on public.purchases;

create policy "purchases_select_own_or_store_owner" on public.purchases
  for select using (
    (select auth.uid()) = user_id
    or exists (select 1 from public.stores s where s.id = purchases.store_id and s.owner_id = (select auth.uid()))
  );

create policy "purchases_insert_own" on public.purchases
  for insert with check ((select auth.uid()) = user_id);

create policy "purchases_update_store_owner" on public.purchases
  for update using (
    exists (select 1 from public.stores s where s.id = purchases.store_id and s.owner_id = (select auth.uid()))
  );

drop policy "store_pins_owner_only" on public.store_pins;
create policy "store_pins_owner_only" on public.store_pins
  for all using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy "scan_events_store_owner_only" on public.scan_events;
create policy "scan_events_store_owner_only" on public.scan_events
  for all using (
    exists (select 1 from public.stores s where s.id = scan_events.store_id and s.owner_id = (select auth.uid()))
  ) with check (
    exists (select 1 from public.stores s where s.id = scan_events.store_id and s.owner_id = (select auth.uid()))
  );

drop policy "device_tokens_owner_only" on public.device_tokens;
create policy "device_tokens_owner_only" on public.device_tokens
  for all using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
