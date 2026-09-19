alter table public.store_pins enable row level security;
create policy "store_pins_owner_only" on public.store_pins
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.scan_events enable row level security;
create policy "scan_events_store_owner_only" on public.scan_events
  for all using (
    exists (select 1 from public.stores s where s.id = scan_events.store_id and s.owner_id = auth.uid())
  ) with check (
    exists (select 1 from public.stores s where s.id = scan_events.store_id and s.owner_id = auth.uid())
  );

alter table public.device_tokens enable row level security;
create policy "device_tokens_owner_only" on public.device_tokens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
