create table public.purchases (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  purchase_date date not null,
  batch_number int,
  status text not null default 'waiting' check (status in ('waiting','notified','collected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, purchase_date)
);
