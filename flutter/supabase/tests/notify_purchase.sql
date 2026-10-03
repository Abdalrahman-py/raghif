-- Asserts 20261003170000_notify_purchase_confirmed.sql: every new purchase
-- asks notify-batch to push its confirmation, with the shared secret.

insert into auth.users (id) values ('00000000-0000-0000-0000-0000000000e1');
insert into public.profiles (id, phone, national_id, pin_hash, name, role)
  values ('00000000-0000-0000-0000-0000000000e1', 'e1', 'e1', 'h', 'buyer', 'buyer');
insert into public.stores (id, name, is_open, daily_bag_limit, bags_remaining)
  values ('00000000-0000-0000-0000-0000000000f1', 'store', true, 10, 10);
truncate net.calls;

insert into public.purchases (id, store_id, user_id, purchase_date, batch_number)
  values ('00000000-0000-0000-0000-0000000000d1',
          '00000000-0000-0000-0000-0000000000f1',
          '00000000-0000-0000-0000-0000000000e1',
          current_date, 1);

do $$
declare c record; n int;
begin
  select count(*) into n from net.calls;
  if n <> 1 then raise exception 'expected 1 push request, got %', n; end if;
  select * into c from net.calls;
  if c.body <> jsonb_build_object('purchaseId', '00000000-0000-0000-0000-0000000000d1') then
    raise exception 'wrong body: %', c.body;
  end if;
  if c.url not like '%/functions/v1/notify-batch' then
    raise exception 'wrong url: %', c.url;
  end if;
  if c.headers->>'x-notify-batch-secret' is distinct from
     (select decrypted_secret from vault.decrypted_secrets where name = 'notify_batch_secret') then
    raise exception 'push request is missing the shared secret';
  end if;
end $$;
