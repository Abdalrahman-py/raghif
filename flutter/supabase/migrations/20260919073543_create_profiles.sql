create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique,
  national_id text unique,
  pin_hash text,
  name text,
  role text not null default 'buyer' check (role in ('buyer','owner')),
  jawwal_pay_number text,
  verification_status text not null default 'pending' check (verification_status in ('pending','verified')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
