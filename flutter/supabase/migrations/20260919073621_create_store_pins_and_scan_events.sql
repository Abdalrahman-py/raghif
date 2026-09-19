create table public.store_pins (
  user_id uuid not null references public.profiles(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, store_id)
);

create table public.scan_events (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  purchase_id uuid references public.purchases(id) on delete set null,
  outcome text not null,
  scanned_name text,
  scanned_national_id text,
  scanned_at timestamptz not null default now()
);
