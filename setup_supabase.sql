-- SUPABASE SCHEMA FOR TANDEM
-- Run this in the Supabase SQL Editor

-- 1. Profiles (Owner details)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  display_name text,
  email text,
  duo_invite_code text unique,
  duo_partner_id uuid references public.profiles(id) on delete set null,
  streak_count int default 0,
  total_xp int default 0,
  tasks_completed int default 0,
  avatar_url text,
  avatar_config jsonb default '{}'::jsonb,
  onboarding_complete boolean default false,
  updated_at timestamptz default now(),
  created_at timestamptz default now()
);

-- 2. Goals
create table public.goals (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  description text,
  category text default 'mindfulness',
  visibility text default 'private' check (visibility in ('public', 'duo', 'private')),
  is_archived boolean default false,
  completed_steps int default 0,
  total_steps int default 1,
  target_date timestamptz,
  created_at timestamptz default now()
);

-- 3. Tasks
create table public.tasks (
  id uuid default gen_random_uuid() primary key,
  goal_id uuid references public.goals(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  is_completed boolean default false,
  reminder_time timestamptz,
  created_at timestamptz default now()
);

-- 4. Duos
create table public.duos (
  id text primary key, -- Deterministic ID like 'uidA_uidB'
  user_a_id uuid references public.profiles(id) on delete cascade not null,
  user_b_id uuid references public.profiles(id) on delete cascade not null,
  combined_streak int default 0,
  created_at timestamptz default now()
);

-- 5. Workout Plans
create table public.workout_plans (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  description text,
  category text,
  difficulty text,
  exercises jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

-- 6. Workout Sessions
create table public.workout_sessions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  plan_id uuid references public.workout_plans(id) on delete set null,
  title text not null,
  started_at timestamptz not null,
  completed_at timestamptz,
  total_volume float default 0,
  data jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- 7. Daily Scores (Stats)
create table public.daily_scores (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  date date not null,
  score int default 0,
  xp_gained int default 0,
  tasks_done int default 0,
  created_at timestamptz default now(),
  unique(user_id, date)
);

-- ── RPC FUNCTIONS ──────────────────────────────────────────

-- 1. Link Partners Transaction
create or replace function public.link_partners(p_user_a uuid, p_user_b uuid)
returns void as $$
declare
  v_duo_id text;
begin
  -- Check if already paired
  if (select duo_partner_id from public.profiles where id = p_user_a) is not null then
    raise exception 'User A already has a partner';
  end if;
  if (select duo_partner_id from public.profiles where id = p_user_b) is not null then
    raise exception 'User B already has a partner';
  end if;

  -- Update profiles
  update public.profiles set duo_partner_id = p_user_b where id = p_user_a;
  update public.profiles set duo_partner_id = p_user_a where id = p_user_b;

  -- Create Duo record
  v_duo_id := case when p_user_a < p_user_b then p_user_a::text || '_' || p_user_b::text
                   else p_user_b::text || '_' || p_user_a::text end;
  
  insert into public.duos (id, user_a_id, user_b_id, combined_streak)
  values (v_duo_id, p_user_a, p_user_b, 0)
  on conflict (id) do nothing;
end;
$$ language plpgsql security definer;

-- 2. Unlink Partners
create or replace function public.unlink_partners(p_user_a uuid, p_user_b uuid)
returns void as $$
begin
  update public.profiles set duo_partner_id = null where id in (p_user_a, p_user_b);
end;
$$ language plpgsql security definer;

-- 3. Increment XP and Stats
create or replace function public.increment_xp(p_user_id uuid, p_amount int, p_task_count int)
returns void as $$
begin
  update public.profiles 
  set total_xp = total_xp + p_amount,
      tasks_completed = tasks_completed + p_task_count
  where id = p_user_id;
end;
$$ language plpgsql security definer;

-- ── ROW LEVEL SECURITY (RLS) ──────────────────────────────────

alter table public.profiles enable row level security;
alter table public.goals enable row level security;
alter table public.tasks enable row level security;
alter table public.duos enable row level security;
alter table public.workout_plans enable row level security;
alter table public.workout_sessions enable row level security;
alter table public.daily_scores enable row level security;

-- Profiles: Users can read all (for pairing search), but only update self
create policy "Profiles are viewable by everyone" on public.profiles for select using (true);
create policy "Users can update their own profile" on public.profiles for update using (auth.uid() = id);

-- Goals: Owner and Partner can view/modify
create policy "Users and partners can access goals" on public.goals
  using (
    auth.uid() = user_id or 
    auth.uid() = (select duo_partner_id from public.profiles where id = user_id)
  );

-- Similar policies for other tables (Tasks, Workouts, etc.)
create policy "Users and partners can access tasks" on public.tasks
  using (
    auth.uid() = user_id or 
    auth.uid() = (select duo_partner_id from public.profiles where id = user_id)
  );

-- Functions and Triggers for Auto-Profile Creation
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, duo_invite_code)
  values (new.id, new.email, upper(substring(md5(random()::text) from 1 for 6)));
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
