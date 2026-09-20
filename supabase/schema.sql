-- Stick · Supabase schema (run in the SQL editor)
create table if not exists public.league (
  user_id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  hours_recovered double precision not null default 0,
  days_held int not null default 0,
  day_number int not null default 0,
  referral_code text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.referrals (
  id bigint generated always as identity primary key,
  code text not null,
  invited_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (invited_user_id)
);

alter table public.league enable row level security;
alter table public.referrals enable row level security;

-- Everyone signed in (anonymous included) can read the league.
create policy "league read" on public.league for select to authenticated using (true);
-- You can only write your own row.
create policy "league upsert own" on public.league for insert to authenticated with check (auth.uid() = user_id);
create policy "league update own" on public.league for update to authenticated using (auth.uid() = user_id);
-- Referral: one insert per invited user.
create policy "referral insert own" on public.referrals for insert to authenticated with check (auth.uid() = invited_user_id);

-- Enable anonymous sign-ins in Authentication › Providers.
