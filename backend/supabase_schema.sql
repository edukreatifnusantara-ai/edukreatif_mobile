-- Toko Kreativ / Supabase schema foundation
-- Run only in the intended Supabase project after review.
-- No credentials are stored in this file.

create type public.user_role as enum ('buyer', 'premium_seller', 'admin');
create type public.product_status as enum ('draft', 'pending_review', 'active', 'rejected', 'inactive');
create type public.order_status as enum ('pending_payment', 'paid', 'processing', 'shipped', 'delivered', 'cancelled');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role public.user_role not null default 'buyer',
  is_premium boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.seller_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  store_name text not null,
  store_description text not null default '',
  review_status text not null default 'pending'
    check (review_status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id),
  title text not null,
  category text not null,
  description text not null default '',
  price integer not null check (price >= 0),
  status public.product_status not null default 'draft',
  cover_path text,
  ebook_path text,
  stock integer check (stock is null or stock >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.shipping_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  label text not null default 'Utama',
  address text not null,
  phone text not null,
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references public.profiles(id),
  shipping_address_id uuid references public.shipping_addresses(id),
  subtotal integer not null check (subtotal >= 0),
  shipping_cost integer not null default 0 check (shipping_cost >= 0),
  total integer not null check (total >= 0),
  status public.order_status not null default 'pending_payment',
  tracking_number text,
  created_at timestamptz not null default now()
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id),
  seller_id uuid not null references public.profiles(id),
  quantity integer not null check (quantity > 0),
  unit_price integer not null check (unit_price >= 0)
);

create table public.ebook_library (
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id),
  order_id uuid not null references public.orders(id),
  granted_at timestamptz not null default now(),
  primary key (buyer_id, product_id)
);

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.ebook_library enable row level security;

create policy "public can read active products" on public.products
  for select using (status = 'active');
create policy "users read own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "buyers read own orders" on public.orders
  for select using (auth.uid() = buyer_id);
create policy "buyers read own ebook library" on public.ebook_library
  for select using (auth.uid() = buyer_id);

-- Seller insert/update and admin moderation policies should be added only
-- after the auth role strategy and server-side payment flow are finalized.
