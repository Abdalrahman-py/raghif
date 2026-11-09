-- Cash on pickup (phase 4 of the launch plan).
--
-- Until a real payment provider is wired in, a bag is paid for in cash at the
-- bakery. This gives the server a record of it: when the owner confirms a
-- collection, one `payments` row is written in the same transaction, with the
-- bakery's price at that moment. The row is the only proof of payment; the app
-- cannot write it.
--
-- A later provider (Jawwal Pay, phase 5) adds its own `method` and statuses to
-- this table rather than replacing it.
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null unique references public.purchases(id) on delete cascade,
  store_id uuid not null references public.stores(id),
  user_id uuid not null references public.profiles(id),
  amount numeric(8, 2) not null check (amount >= 0),
  method text not null default 'cash' check (method in ('cash')),
  status text not null default 'paid' check (status in ('paid')),
  created_at timestamptz not null default now()
);

create index if not exists payments_store_created_idx
  on public.payments (store_id, created_at desc);
create index if not exists payments_user_idx on public.payments (user_id);

alter table public.payments enable row level security;
revoke all on public.payments from anon, authenticated;
grant select on public.payments to authenticated;

-- The buyer sees their own payments; an owner sees their bakery's.
create policy payments_select_own on public.payments
  for select to authenticated
  using (user_id = (select auth.uid()));
create policy payments_select_owner on public.payments
  for select to authenticated
  using (exists (
    select 1 from public.stores s
     where s.id = payments.store_id and s.owner_id = (select auth.uid())));

-- Collecting a bag now also records the cash taken, once. Same lock order as
-- before: stores row first, then the purchase row.
create or replace function public.collect_purchase(p_purchase_id uuid)
returns public.purchases
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_p public.purchases;
  v_store_id uuid;
  v_price numeric(8, 2);
begin
  select store_id into v_store_id from public.purchases where id = p_purchase_id;
  select bag_price into v_price from public.stores
   where id = v_store_id and owner_id = auth.uid() for update;
  if not found then raise exception 'not the store owner'; end if;
  select * into v_p from public.purchases where id = p_purchase_id for update;
  if v_p.purchase_date <> (now() at time zone 'Asia/Hebron')::date then
    raise exception 'collection is for today only';
  end if;
  if v_p.status = 'waiting' then raise exception 'batch not notified yet'; end if;
  update public.purchases set status = 'collected'
   where id = p_purchase_id returning * into v_p;
  insert into public.payments (purchase_id, store_id, user_id, amount)
  values (v_p.id, v_p.store_id, v_p.user_id, v_price)
  on conflict (purchase_id) do nothing;
  return v_p;
end $$;

-- The owner's day summary gains the cash taken that day.
drop function if exists public.store_daily_summaries(uuid, integer);
create function public.store_daily_summaries(p_store_id uuid, p_limit integer default 30)
returns table(purchase_date date, sold bigint, collected bigint,
              not_collected bigint, cash_total numeric)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (select 1 from public.stores
                  where id = p_store_id and owner_id = (select auth.uid()))
  then raise exception 'not the store owner' using errcode = 'P0001'; end if;
  return query
    select p.purchase_date,
           count(*),
           count(*) filter (where p.status = 'collected'),
           count(*) filter (where p.status <> 'collected'),
           coalesce(sum(pay.amount), 0)
      from public.purchases p
      left join public.payments pay on pay.purchase_id = p.id
     where p.store_id = p_store_id
     group by p.purchase_date
     order by p.purchase_date desc
     limit greatest(p_limit, 1);
end; $$;

revoke execute on function public.store_daily_summaries(uuid, integer)
  from public, anon, authenticated;
grant execute on function public.store_daily_summaries(uuid, integer) to authenticated;
revoke execute on function public.collect_purchase(uuid)
  from public, anon, authenticated;
grant execute on function public.collect_purchase(uuid) to authenticated;
