alter table public.stores enable row level security;

create policy "stores_select_public" on public.stores
  for select using (true);

create policy "stores_owner_write" on public.stores
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
