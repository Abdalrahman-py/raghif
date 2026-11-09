-- Server-side fixes from the review of PR 68 (Obaida's admin/payments work).
--
-- 1. A simulated wallet payment is not money. `record_wallet_payment` writes
--    `method = 'jawwal_pay', provider = 'simulated'` with no real provider and
--    no code check, so the buyer still pays cash at the counter (the app has
--    shown it as unpaid since 4f358a2). Smallest correct fix: when the owner
--    collects such a bag, `collect_purchase` turns the simulated row into the
--    cash row (current price, now). `store_daily_summaries` already counts
--    `method = 'cash'` only, so cash taken now includes those bags and a
--    simulated payment is never counted as received. A real provider row
--    (`provider = 'jawwal_pay'`) is left alone. Rows collected before this
--    migration are not rewritten: nobody knows whether cash was taken then.
-- 2. `record_wallet_payment` locked the purchase row first. It now locks the
--    stores row first, then the purchase row, like every other queue RPC.
-- 3. `popular_stores` let `anon` aggregate `purchases`. Dropped: its only
--    caller was the signed-out home, which now ranks by today's sales from
--    `stores` (the fallback it already had). Older app builds get an error
--    from the call and use that same fallback.
-- 4. `reserve_bag` and `record_scan` move to `search_path = ''`. Their bodies
--    already qualify every object, so only the setting changes; the
--    Asia/Hebron date check and the lock order are untouched.

create or replace function public.record_wallet_payment(p_purchase_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_store_id uuid;
  v_price numeric(8, 2);
  v_p public.purchases;
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '42501'; end if;
  select store_id into v_store_id from public.purchases
   where id = p_purchase_id and user_id = v_uid;
  if v_store_id is null then raise exception 'purchase not found'; end if;
  -- Lock order: stores row first, then the purchase row.
  select bag_price into v_price from public.stores where id = v_store_id for update;
  select * into v_p from public.purchases
   where id = p_purchase_id and user_id = v_uid for update;
  if v_p.id is null then raise exception 'purchase not found'; end if;
  if v_p.purchase_date <> (now() at time zone 'Asia/Hebron')::date then
    raise exception 'payment is for today only';
  end if;
  if v_p.status = 'collected' then raise exception 'already collected'; end if;
  insert into public.payments (purchase_id, store_id, user_id, amount, method, provider)
  values (v_p.id, v_p.store_id, v_p.user_id, v_price, 'jawwal_pay', 'simulated')
  on conflict (purchase_id) do nothing;
end $$;

revoke execute on function public.record_wallet_payment(uuid)
  from public, anon, authenticated;
grant execute on function public.record_wallet_payment(uuid) to authenticated;

-- Collecting a bag records the cash taken, once. A simulated wallet payment
-- moved no money, so it becomes the cash row; a real one stays as it is.
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
  on conflict (purchase_id) do update
    set method = 'cash', provider = null,
        amount = excluded.amount, created_at = now()
    where public.payments.provider = 'simulated';
  return v_p;
end $$;

revoke execute on function public.collect_purchase(uuid)
  from public, anon, authenticated;
grant execute on function public.collect_purchase(uuid) to authenticated;

drop function if exists public.popular_stores(int);

alter function public.reserve_bag(uuid, date) set search_path = '';
alter function public.record_scan(uuid, text, uuid, text) set search_path = '';
