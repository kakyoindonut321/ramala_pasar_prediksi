-- 001_schema.sql : tabel, constraint, trigger, RLS, grant
-- Jalankan di Supabase SQL Editor (urut: 001 lalu 002).

create extension if not exists pgcrypto with schema extensions;

-- Default aman: objek baru TIDAK bisa diakses client kecuali di-grant eksplisit.
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;

-- ========== TABEL ==========

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{3,20}$'),
  display_name text check (char_length(display_name) between 1 and 40),
  avatar_url text check (avatar_url is null or (char_length(avatar_url) <= 300 and avatar_url like 'https://res.cloudinary.com/%')),
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now()
);

create table public.wallets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  balance numeric(14,4) not null default 1000 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create table public.markets (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 5 and 140),
  description text check (char_length(description) <= 1000),
  category text not null default 'general' check (category ~ '^[a-z0-9_]{2,20}$'),
  image_url text check (image_url is null or (char_length(image_url) <= 300 and image_url like 'https://res.cloudinary.com/%')),
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  close_at timestamptz not null,
  status text not null default 'open' check (status in ('open','resolved','cancelled')),
  outcome text check (outcome in ('yes','no')),
  b double precision not null default 100 check (b between 10 and 1000),
  q_yes double precision not null default 0,
  q_no double precision not null default 0,
  price_yes numeric(8,6) not null default 0.5 check (price_yes between 0 and 1),
  volume numeric(16,4) not null default 0,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  check ((status = 'resolved') = (outcome is not null)),
  check ((latitude is null) = (longitude is null))
);

create table public.positions (
  user_id uuid not null references public.profiles(id) on delete cascade,
  market_id uuid not null references public.markets(id) on delete cascade,
  side text not null check (side in ('yes','no')),
  shares numeric(12,2) not null default 0 check (shares >= 0),
  cost numeric(14,4) not null default 0 check (cost >= 0),
  realized_pnl numeric(14,4) not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, market_id, side)
);

create table public.trades (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  market_id uuid not null references public.markets(id) on delete cascade,
  side text not null check (side in ('yes','no')),
  action text not null check (action in ('buy','sell','payout')),
  shares numeric(12,2) not null check (shares >= 0),
  amount numeric(14,4) not null check (amount >= 0),
  price_yes_after numeric(8,6) not null,
  created_at timestamptz not null default now()
);

create table public.price_history (
  id bigint generated always as identity primary key,
  market_id uuid not null references public.markets(id) on delete cascade,
  price_yes numeric(8,6) not null,
  created_at timestamptz not null default now()
);

-- Blockchain sederhana: hash = sha256(idx|prev_hash|data)
create table public.ledger (
  idx bigint primary key,
  prev_hash text not null,
  data text not null,
  hash text not null unique,
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type ~ '^[a-z_]{2,30}$'),
  title text not null check (char_length(title) between 1 and 100),
  body text not null check (char_length(body) <= 300),
  data jsonb not null default '{}',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  impression text not null check (char_length(impression) between 1 and 1000),
  suggestion text not null check (char_length(suggestion) between 1 and 1000),
  rating smallint check (rating between 1 and 5),
  created_at timestamptz not null default now()
);

create table public.game_scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  game text not null check (game ~ '^[a-z0-9_]{2,30}$'),
  score integer not null check (score between 0 and 100000),
  created_at timestamptz not null default now()
);

-- ========== INDEX ==========
create index on public.markets (status, close_at);
create index on public.markets (category);
create index on public.positions (user_id);
create index on public.trades (user_id, created_at desc);
create index on public.trades (market_id);
create index on public.price_history (market_id, created_at);
create index on public.notifications (user_id, created_at desc);
create index on public.game_scores (game, score desc);

-- ========== TRIGGER: user baru -> profil + dompet ==========
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  u text := lower(coalesce(new.raw_user_meta_data->>'username', ''));
  fb text := 'user_' || substr(replace(new.id::text, '-', ''), 1, 8);
begin
  if u !~ '^[a-z0-9_]{3,20}$' then u := fb; end if;
  begin
    insert into profiles(id, username, display_name) values (new.id, u, u);
  exception when unique_violation then
    insert into profiles(id, username, display_name) values (new.id, fb, u);
  end;
  insert into wallets(user_id) values (new.id);
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ========== RLS ==========
alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.markets enable row level security;
alter table public.positions enable row level security;
alter table public.trades enable row level security;
alter table public.price_history enable row level security;
alter table public.ledger enable row level security;
alter table public.notifications enable row level security;
alter table public.feedback enable row level security;
alter table public.game_scores enable row level security;

create policy profiles_read on public.profiles for select to authenticated using (true);
create policy profiles_update_own on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy wallets_read_own on public.wallets for select to authenticated using (user_id = auth.uid());
create policy markets_read on public.markets for select to authenticated using (true);
create policy positions_read_own on public.positions for select to authenticated using (user_id = auth.uid());
create policy trades_read_own on public.trades for select to authenticated using (user_id = auth.uid());
create policy price_history_read on public.price_history for select to authenticated using (true);
create policy ledger_read on public.ledger for select to authenticated using (true);
create policy notif_read_own on public.notifications for select to authenticated using (user_id = auth.uid());
create policy notif_update_own on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy feedback_read_own on public.feedback for select to authenticated using (user_id = auth.uid());
create policy feedback_insert_own on public.feedback for insert to authenticated with check (user_id = auth.uid());
create policy scores_read on public.game_scores for select to authenticated using (true);
create policy scores_insert_own on public.game_scores for insert to authenticated with check (user_id = auth.uid());

-- ========== GRANT (client hanya boleh yang di bawah ini) ==========
grant select on public.profiles, public.wallets, public.markets, public.positions, public.trades,
  public.price_history, public.ledger, public.notifications, public.feedback, public.game_scores
  to authenticated;
grant update (username, display_name, avatar_url) on public.profiles to authenticated; -- role TIDAK bisa diubah client
grant update (is_read) on public.notifications to authenticated;
grant insert (impression, suggestion, rating) on public.feedback to authenticated;
grant insert (game, score) on public.game_scores to authenticated;

-- ========== REALTIME ==========
alter publication supabase_realtime add table public.notifications, public.markets;