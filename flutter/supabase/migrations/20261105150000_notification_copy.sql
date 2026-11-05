-- Clearer Arabic copy for the three booking notifications, with dates as
-- DD/MM/YYYY instead of ISO. Same triggers, same kinds; only the text changes.

create or replace function public.persist_purchase_notification()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_kind text; v_title text; v_body text; v_store text;
begin
  select name into v_store from public.stores where id = new.store_id;
  if tg_op = 'INSERT' then
    v_kind := 'confirmed';
    v_title := 'تم تأكيد حجزك';
    v_body := format('حجزت رغيفك من %s ليوم %s. سنخبرك فور أن يحين دورك.',
                     v_store, to_char(new.purchase_date, 'DD/MM/YYYY'));
  elsif new.purchase_date is distinct from old.purchase_date then
    v_kind := 'postponed';
    v_title := 'تم تأجيل حجزك';
    v_body := format('نقلنا حجزك من %s إلى يوم %s. سنخبرك عندما يحين دورك.',
                     v_store, to_char(new.purchase_date, 'DD/MM/YYYY'));
  elsif new.status = 'notified' and old.status is distinct from 'notified' then
    v_kind := 'ready';
    v_title := 'حان دورك، تفضّل بالاستلام';
    v_body := format('رغيفك جاهز في %s. افتح الحجز وأظهر رمز الاستلام للمخبز.', v_store);
  else
    return null;
  end if;
  insert into public.notification_inbox(user_id,purchase_id,kind,title,body)
    values (new.user_id,new.id,v_kind,v_title,v_body);
  return null;
end $$;
revoke all on function public.persist_purchase_notification() from public, anon, authenticated;
