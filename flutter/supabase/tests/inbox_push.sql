-- Asserts 20261104105000_inbox_push_trigger.sql: postponed and announcement
-- rows ask send-push to deliver them (with the shared secret); confirmed and
-- ready rows do not, because notify-batch already pushes those. Rollback-only.
begin;

insert into auth.users (id) values ('c0000000-0000-0000-0000-000000000001');
insert into public.profiles (id, phone, pin_hash, name, role)
  values ('c0000000-0000-0000-0000-000000000001', 'push-1', 'h', 'push-buyer', 'buyer');

truncate net.calls;

-- Already pushed elsewhere: no second push.
insert into public.notification_inbox (user_id, kind, title, body) values
  ('c0000000-0000-0000-0000-000000000001', 'confirmed', 't', 'b'),
  ('c0000000-0000-0000-0000-000000000001', 'ready', 't', 'b');
do $$ begin
  if (select count(*) from net.calls) <> 0 then
    raise exception 'confirmed/ready must not be pushed from the inbox trigger';
  end if;
end $$;

-- Not pushed anywhere else: one request each.
insert into public.notification_inbox (id, user_id, kind, title, body) values
  ('c1000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'postponed', 't', 'b'),
  ('c1000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'announcement', 't', 'b');
do $$
declare c record;
begin
  if (select count(*) from net.calls) <> 2 then
    raise exception 'expected 2 push requests, got %', (select count(*) from net.calls);
  end if;
  for c in select * from net.calls loop
    if c.url not like '%/functions/v1/send-push' then
      raise exception 'wrong url: %', c.url;
    end if;
    if c.headers->>'x-notify-batch-secret' is distinct from
       (select decrypted_secret from vault.decrypted_secrets where name = 'notify_batch_secret') then
      raise exception 'push request is missing the shared secret';
    end if;
  end loop;
  if not exists (select 1 from net.calls where body = jsonb_build_object('inboxId', 'c1000000-0000-0000-0000-000000000001'))
     or not exists (select 1 from net.calls where body = jsonb_build_object('inboxId', 'c1000000-0000-0000-0000-000000000002')) then
    raise exception 'push bodies do not carry the inbox ids: %', (select jsonb_agg(body) from net.calls);
  end if;
end $$;

-- A missing secret must not stop the row from being written.
delete from vault.secrets where name = 'notify_batch_secret';
truncate net.calls;
insert into public.notification_inbox (id, user_id, kind, title, body)
  values ('c1000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001', 'announcement', 't', 'b');
do $$ begin
  if not exists (select 1 from public.notification_inbox where id = 'c1000000-0000-0000-0000-000000000003') then
    raise exception 'the inbox row was lost when the push could not be sent';
  end if;
  if (select count(*) from net.calls) <> 0 then
    raise exception 'no push may be sent without the secret';
  end if;
end $$;

-- The trigger function is not callable by clients.
do $$ begin
  if has_function_privilege('authenticated', 'public.trigger_push_inbox()', 'EXECUTE')
     or has_function_privilege('anon', 'public.trigger_push_inbox()', 'EXECUTE') then
    raise exception 'trigger function is executable by clients';
  end if;
end $$;

rollback;
