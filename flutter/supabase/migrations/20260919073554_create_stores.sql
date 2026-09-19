create table public.stores (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid references auth.users(id),
  is_open boolean not null default false,
  daily_bag_limit int not null default 0,
  bags_remaining int not null default 0 check (bags_remaining >= 0),
  open_time time,
  close_time time,
  batch_size int not null default 20,
  area text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
