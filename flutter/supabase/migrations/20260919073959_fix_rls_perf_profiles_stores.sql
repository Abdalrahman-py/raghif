drop policy "profiles_select_own" on public.profiles;
drop policy "profiles_select_by_store_owner" on public.profiles;
drop policy "profiles_update_own" on public.profiles;
drop policy "profiles_insert_own" on public.profiles;

create policy "profiles_select" on public.profiles
  for select using (
    (select auth.uid()) = id
    or exists (
      select 1 from public.purchases p
      join public.stores s on s.id = p.store_id
      where p.user_id = profiles.id and s.owner_id = (select auth.uid())
    )
  );

create policy "profiles_update_own" on public.profiles
  for update using ((select auth.uid()) = id);

create policy "profiles_insert_own" on public.profiles
  for insert with check ((select auth.uid()) = id);

drop policy "stores_owner_write" on public.stores;

create policy "stores_owner_insert" on public.stores
  for insert with check ((select auth.uid()) = owner_id);

create policy "stores_owner_update" on public.stores
  for update using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);

create policy "stores_owner_delete" on public.stores
  for delete using ((select auth.uid()) = owner_id);
