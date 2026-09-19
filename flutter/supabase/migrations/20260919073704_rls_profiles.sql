alter table public.profiles enable row level security;

create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles_select_by_store_owner" on public.profiles
  for select using (
    exists (
      select 1 from public.purchases p
      join public.stores s on s.id = p.store_id
      where p.user_id = profiles.id and s.owner_id = auth.uid()
    )
  );

create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);
