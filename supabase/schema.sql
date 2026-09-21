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

-- In-app account deletion (App Review 5.1.1(v)). Runs as the calling user only.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.league where user_id = auth.uid();
  delete from public.referrals where invited_user_id = auth.uid();
  delete from auth.users where id = auth.uid();
end;
$$;
grant execute on function public.delete_own_account() to authenticated;
