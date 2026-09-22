-- ============================================================================
-- HRMS Phase 1 Migration
-- Scope: HR users/roles, Applications intake (website + consent), Audit log.
-- Later phases (ml_evaluations, assessments, ai_interviews, interviews,
-- offers, etc.) are intentionally NOT created here — see Section 26 phasing
-- in the project doc. Adding them later as 0002_*.sql, 0003_*.sql etc.
-- ============================================================================

-- ---------- Extensions ----------
create extension if not exists "pgcrypto";      -- gen_random_uuid()
create extension if not exists "citext";         -- case-insensitive email matching

-- ---------- Enums ----------
create type user_role as enum ('hr_admin', 'interviewer');

create type application_source as enum ('WEBSITE', 'EMAIL');

-- Only the statuses reachable in Phase 1 are active; later phases will need
-- an ALTER TYPE ... ADD VALUE for each new pipeline stage (Section 11).
create type application_status as enum (
  'Application Received',
  'Under Review',
  'Withdrawn'
);

create type audit_role as enum ('hr', 'interviewer', 'system');

-- ============================================================================
-- users  (Section 12.17) — HR/Admin + Interviewer accounts.
-- Auth itself is handled by Supabase Auth; this table stores the app-level
-- profile/role that hangs off auth.users.id.
-- ============================================================================
create table users (
  user_id       uuid primary key references auth.users(id) on delete cascade,
  email         citext not null unique,
  role          user_role not null default 'hr_admin',
  mfa_enabled   boolean not null default false,
  invited_by    uuid references users(user_id),
  created_at    timestamptz not null default now()
);

comment on table users is 'App-level profile for Supabase Auth users. MFA is mandatory for hr_admin at the application layer (Section 14).';

-- ============================================================================
-- applications  (Section 12.1)
-- Only the Phase-1-relevant fields are included; fields for later stages
-- (assessment/ai-interview status values, etc.) are added by future
-- migrations via ALTER TABLE so this migration matches actual Phase 1 scope.
-- ============================================================================
create table applications (
  application_id      uuid primary key default gen_random_uuid(),
  candidate_id         uuid not null default gen_random_uuid(),

  candidate_name        text not null,
  email                  citext not null,
  phone                  text,

  department             text not null,
  position                text not null,

  source                  application_source not null,
  application_date         timestamptz not null default now(),

  resume_url                text,

  education                  jsonb default '[]'::jsonb,
  skills                      jsonb default '[]'::jsonb,
  experience                  jsonb default '[]'::jsonb,
  projects                    jsonb default '[]'::jsonb,

  portfolio                    text,
  github                        text,
  linkedin                      text,

  current_status                application_status not null default 'Application Received',

  duplicate_of                   uuid references applications(application_id),

  retention_expires_at             timestamptz,

  email_bounced                     boolean not null default false,
  email_bounce_reason                 text,

  -- Consent capture (Section 6.1 / 16)
  consent_version                      text not null,
  consented_at                          timestamptz not null default now(),

  withdrawn_at                           timestamptz,

  created_at                              timestamptz not null default now(),
  updated_at                               timestamptz not null default now()
);

create index idx_applications_status on applications(current_status);
create index idx_applications_email on applications(email);
create index idx_applications_department_position on applications(department, position);
create index idx_applications_source on applications(source);

-- keep updated_at fresh
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_applications_updated_at
before update on applications
for each row execute function set_updated_at();

-- ============================================================================
-- audit_logs  (Section 12.16) — append-only, no UPDATE/DELETE at DB role level
-- ============================================================================
create table audit_logs (
  log_id            uuid primary key default gen_random_uuid(),
  hr_user            uuid references users(user_id),
  role                 audit_role not null,
  action                text not null,
  candidate_id           uuid,
  previous_status         text,
  new_status               text,
  metadata                  jsonb default '{}'::jsonb,
  timestamp                 timestamptz not null default now()
);

create index idx_audit_logs_candidate on audit_logs(candidate_id);
create index idx_audit_logs_timestamp on audit_logs(timestamp desc);

-- Enforce append-only at the DB role level: revoke UPDATE/DELETE from the
-- application role (adjust role name to match your Supabase/Postgres role).
-- Run these once your app DB role exists:
--   revoke update, delete on audit_logs from authenticated;
--   revoke update, delete on audit_logs from service_role_app; -- if you split roles

-- ============================================================================
-- Row Level Security
-- ============================================================================
alter table applications enable row level security;
alter table audit_logs enable row level security;
alter table users enable row level security;

-- HR/Admin: full read/write on applications.
create policy hr_admin_full_access_applications on applications
  for all
  using (
    exists (select 1 from users u where u.user_id = auth.uid() and u.role = 'hr_admin')
  )
  with check (
    exists (select 1 from users u where u.user_id = auth.uid() and u.role = 'hr_admin')
  );

-- Audit logs: readable by hr_admin only in Phase 1 (interviewer-visible
-- filtering arrives with the Interviewer role work).
create policy hr_admin_read_audit_logs on audit_logs
  for select
  using (
    exists (select 1 from users u where u.user_id = auth.uid() and u.role = 'hr_admin')
  );

-- Inserts to audit_logs happen via the backend service role, not directly
-- from authenticated users, so no insert policy for 'authenticated' here.

-- Users: a user can read their own profile; hr_admin can read all.
create policy self_read_users on users
  for select
  using (auth.uid() = user_id or exists (
    select 1 from users u where u.user_id = auth.uid() and u.role = 'hr_admin'
  ));

-- ============================================================================
-- Seed note: create your first hr_admin manually after signing up via
-- Supabase Auth, e.g.:
--   insert into users (user_id, email, role, mfa_enabled)
--   values ('<auth.users.id>', 'you@company.com', 'hr_admin', true);
-- ============================================================================
