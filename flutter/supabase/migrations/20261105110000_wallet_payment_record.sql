-- Wallet payments, simulated for now (launch plan, phase 5 groundwork).
--
-- The app can ask for payment through "Jawwal Pay" before booking. Until the
-- real provider is connected the confirmation code is a fixed test code and no
-- money moves, so the payment is recorded with provider = 'simulated': a flag
-- that reports and the owner can see, never mistaken for cash received.
--
-- One payment per purchase (the unique key from the cash migration): a bag paid
-- through the wallet is not charged again as cash when it is collected,
-- because collect_purchase's insert finds the row and does nothing.
alter table public.payments
  add column if not exists provider text
    check (provider is null or provider in ('simulated', 'jawwal_pay'));

alter table public.payments drop constraint if exists payments_method_check;
alter table public.payments
  add constraint payments_method_check check (method in ('cash', 'jawwal_pay'));

-- Records the wallet payment for the caller's own booking of today. The price
-- is the bakery's, never a client value.
create or replace function public.record_wallet_payment(p_purchase_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_p public.purchases;
  v_price numeric(8, 2);
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '42501'; end if;
  select * into v_p from public.purchases
   where id = p_purchase_id and user_id = v_uid for update;
  if v_p.id is null then raise exception 'purchase not found'; end if;
  if v_p.purchase_date <> (now() at time zone 'Asia/Hebron')::date then
    raise exception 'payment is for today only';
  end if;
  if v_p.status = 'collected' then raise exception 'already collected'; end if;
  select bag_price into v_price from public.stores where id = v_p.store_id;
  insert into public.payments (purchase_id, store_id, user_id, amount, method, provider)
  values (v_p.id, v_p.store_id, v_p.user_id, v_price, 'jawwal_pay', 'simulated')
  on conflict (purchase_id) do nothing;
end $$;

revoke execute on function public.record_wallet_payment(uuid)
  from public, anon, authenticated;
grant execute on function public.record_wallet_payment(uuid) to authenticated;

-- "Cash taken" is cash only: a wallet-paid bag adds nothing to the till.
create or replace function public.store_daily_summaries(p_store_id uuid, p_limit integer default 30)
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
           coalesce(sum(pay.amount) filter (where pay.method = 'cash'), 0)
      from public.purchases p
      left join public.payments pay on pay.purchase_id = p.id
     where p.store_id = p_store_id
     group by p.purchase_date
     order by p.purchase_date desc
     limit greatest(p_limit, 1);
end; $$;
