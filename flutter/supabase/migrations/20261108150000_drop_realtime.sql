-- The app no longer keeps a live (Realtime) connection: screens read on open,
-- on pull-to-refresh, after the person's own actions and when a push arrives.
-- Leaving the tables in the publication would only make the server compute
-- and fan out changes nobody listens to.
alter publication supabase_realtime drop table public.purchases;
alter publication supabase_realtime drop table public.stores;
