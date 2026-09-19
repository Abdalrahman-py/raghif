alter table public.purchases enable row level security;

create policy "purchases_select_own_or_store_owner" on public.purchases
  for select using (
    auth.uid() = user_id
    or exists (select 1 from public.stores s where s.id = purchases.store_id and s.owner_id = auth.uid())
  );

create policy "purchases_insert_own" on public.purchases
  for insert with check (auth.uid() = user_id);

create policy "purchases_update_store_owner" on public.purchases
  for update using (
    exists (select 1 from public.stores s where s.id = purchases.store_id and s.owner_id = auth.uid())
  );
