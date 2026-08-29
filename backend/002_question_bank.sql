-- Edukreativ Mobile: question bank and admin operations
-- Apply after backend/supabase_schema.sql in the intended Supabase project.
-- This migration contains no credentials.

create type public.question_status as enum (
  'draft', 'pending_review', 'approved', 'published', 'rejected', 'archived'
);

create table public.question_subjects (
  code text primary key,
  title text not null,
  created_at timestamptz not null default now()
);

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  source_id text,
  source_number integer,
  subject_code text not null references public.question_subjects(code),
  topic text not null default '',
  subtopic text not null default '',
  prompt text not null,
  options jsonb not null default '{}'::jsonb,
  answer text not null,
  explanation text not null default '',
  difficulty text not null default 'medium'
    check (difficulty in ('easy', 'medium', 'hard')),
  estimated_seconds integer check (estimated_seconds is null or estimated_seconds > 0),
  status public.question_status not null default 'draft',
  source_name text not null default '',
  rights_status text not null default 'unknown'
    check (rights_status in ('unknown', 'owned', 'licensed', 'public_domain', 'restricted')),
  version integer not null default 1 check (version > 0),
  created_by uuid references public.profiles(id),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint questions_options_object check (jsonb_typeof(options) = 'object'),
  constraint questions_answer_present check (options ? answer)
);

create index questions_status_idx on public.questions(status);
create index questions_subject_topic_idx on public.questions(subject_code, topic);
create index questions_source_idx on public.questions(source_name, source_number);

create table public.question_audit_log (
  id bigint generated always as identity primary key,
  question_id uuid references public.questions(id) on delete set null,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null check (action in ('created', 'updated', 'submitted', 'reviewed', 'published', 'archived', 'rejected')),
  before_data jsonb,
  after_data jsonb,
  note text not null default '',
  created_at timestamptz not null default now()
);

create table public.question_review_queue (
  id bigint generated always as identity primary key,
  question_id uuid not null references public.questions(id) on delete cascade,
  requested_by uuid references public.profiles(id) on delete set null,
  status text not null default 'queued' check (status in ('queued', 'in_review', 'completed', 'cancelled')),
  priority integer not null default 0,
  note text not null default '',
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.question_subjects enable row level security;
alter table public.questions enable row level security;
alter table public.question_audit_log enable row level security;
alter table public.question_review_queue enable row level security;

-- Keep the role check server-side and reusable by RLS policies.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

grant execute on function public.is_admin() to authenticated;

-- Published questions are visible to signed-in learners. Admins can see all.
create policy "signed in users read published questions"
  on public.questions for select to authenticated
  using (status = 'published' or public.is_admin());

create policy "admins manage questions"
  on public.questions for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "users read subjects"
  on public.question_subjects for select to authenticated using (true);

create policy "admins manage subjects"
  on public.question_subjects for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "admins read audit log"
  on public.question_audit_log for select to authenticated using (public.is_admin());

create policy "admins insert audit log"
  on public.question_audit_log for insert to authenticated with check (public.is_admin());

create policy "admins manage review queue"
  on public.question_review_queue for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- Keep updated_at current for question edits.
create or replace function public.touch_question_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger questions_touch_updated_at
before update on public.questions
for each row execute function public.touch_question_updated_at();

-- Seed only taxonomy, never learner or admin data.
insert into public.question_subjects (code, title) values
  ('PU', 'Penalaran Umum'),
  ('PPU', 'Pengetahuan dan Pemahaman Umum'),
  ('PBM', 'Pemahaman Bacaan dan Menulis'),
  ('PK', 'Pengetahuan Kuantitatif'),
  ('LBE', 'Literasi Bahasa Inggris'),
  ('PM', 'Penalaran Matematika')
on conflict (code) do update set title = excluded.title;
