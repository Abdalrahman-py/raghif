-- Admin panel, step 3: announcements in the notification inbox.
--
-- The inbox stays the single place notifications live (the trigger on
-- purchases still writes the transactional ones). Announcements are written
-- by the administrator and have no purchase behind them, so purchase_id may
-- now be null.
--
-- WARNING for rollout: an app build that still reads purchase_id as a
-- non-null string cannot parse an announcement row. Do not send one until the
-- app that tolerates null purchase_id is out. (Push delivery is a later step.)

alter table public.notification_inbox
  alter column purchase_id drop not null;

do $$
declare
  c text;
begin
  for c in
    select conname from pg_constraint
     where conrelid = 'public.notification_inbox'::regclass
       and contype = 'c'
       and pg_get_constraintdef(oid) like '%kind%'
  loop
    execute format('alter table public.notification_inbox drop constraint %I', c);
  end loop;
end $$;

alter table public.notification_inbox
  add constraint notification_inbox_kind_check
  check (kind in ('confirmed', 'ready', 'postponed', 'announcement'));

-- Sends one announcement to a set of people by writing their inbox rows.
-- [p_target]:
--   'store'   the owner of [p_store]
--   'buyers'  every active buyer
--   'owners'  every active owner
--   'all'     every active account
-- Returns how many rows were written.
create or replace function public.admin_send_notification(
  p_target text,
  p_title text,
  p_body text,
  p_store uuid default null
)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_title text := btrim(coalesce(p_title, ''));
  v_body text := btrim(coalesce(p_body, ''));
  v_count int;
begin
  if not public.is_admin() then raise exception 'not authorized'; end if;
  if v_title = '' or char_length(v_title) > 80 then
    raise exception 'invalid title';
  end if;
  if v_body = '' or char_length(v_body) > 400 then
    raise exception 'invalid body';
  end if;
  if p_target not in ('store', 'buyers', 'owners', 'all') then
    raise exception 'invalid target';
  end if;
  if p_target = 'store' and not exists (
    select 1 from public.stores where id = p_store and owner_id is not null
  ) then
    raise exception 'store not found';
  end if;

  insert into public.notification_inbox (user_id, purchase_id, kind, title, body)
  select pr.id, null, 'announcement', v_title, v_body
    from public.profiles pr
   where pr.account_status = 'active'
     and (
       (p_target = 'store'  and pr.id = (select owner_id from public.stores where id = p_store))
       or (p_target = 'buyers' and pr.role = 'buyer')
       or (p_target = 'owners' and pr.role = 'owner')
       or p_target = 'all'
     );
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke execute on function public.admin_send_notification(text, text, text, uuid)
  from public, anon, authenticated;
grant execute on function public.admin_send_notification(text, text, text, uuid)
  to authenticated, service_role;
