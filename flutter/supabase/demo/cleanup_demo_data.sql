-- Removes everything seed_demo_data.sql added (and nothing else): the demo
-- bakeries, the demo accounts, and every booking, payment, pin and
-- notification that touches them, including bookings a real account made at a
-- demo bakery while testing.
--
-- Demo ids look like  de[012]00000-0000-4000-8000-...

begin;

delete from public.notification_inbox
 where user_id::text ~ '^de1[0-9a-f]{5}-0000-4000-8000-'
    or purchase_id in (
         select id from public.purchases
          where store_id::text ~ '^de0[0-9a-f]{5}-0000-4000-8000-'
             or user_id::text  ~ '^de1[0-9a-f]{5}-0000-4000-8000-');

delete from public.payments
 where store_id::text ~ '^de0[0-9a-f]{5}-0000-4000-8000-'
    or user_id::text  ~ '^de1[0-9a-f]{5}-0000-4000-8000-';

delete from public.purchases
 where store_id::text ~ '^de0[0-9a-f]{5}-0000-4000-8000-'
    or user_id::text  ~ '^de1[0-9a-f]{5}-0000-4000-8000-';

delete from public.store_pins
 where store_id::text ~ '^de0[0-9a-f]{5}-0000-4000-8000-'
    or user_id::text  ~ '^de1[0-9a-f]{5}-0000-4000-8000-';

delete from public.stores
 where id::text ~ '^de0[0-9a-f]{5}-0000-4000-8000-';

-- Profiles go with their auth users (ON DELETE CASCADE).
delete from auth.users
 where id::text ~ '^de1[0-9a-f]{5}-0000-4000-8000-';

commit;
