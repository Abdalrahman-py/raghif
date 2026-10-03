-- Minimal stand-ins for the Supabase platform pieces the migrations lean on,
-- so they can run against a plain Postgres. Not a substitute for the real
-- thing: it exists to exercise RLS, grants and the RPC bodies.
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;

create schema extensions;
create extension pgcrypto schema extensions;
create schema auth;
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as
  $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

create schema vault;
create table vault.secrets (id uuid default gen_random_uuid(), name text, secret text);
create view vault.decrypted_secrets as select id, name, secret as decrypted_secret from vault.secrets;
create function vault.create_secret(s text, n text, d text default null) returns uuid
  language sql as $$ insert into vault.secrets (name, secret) values (n, s) returning id $$;
create schema net;
-- Records every call so tests can assert what would have been sent.
create table net.calls (url text, headers jsonb, body jsonb);
create function net.http_post(url text, headers jsonb default '{}', body jsonb default '{}')
  returns bigint language sql as $$
    insert into net.calls values (url, headers, body); select 1::bigint
  $$;
create publication supabase_realtime;

grant usage on schema public, extensions to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant execute on functions to anon, authenticated, service_role;
