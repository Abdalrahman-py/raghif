create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  fcm_token text not null,
  platform text not null,
  updated_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);
