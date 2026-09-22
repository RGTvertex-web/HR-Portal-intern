-- ============================================================================
-- HRMS Phase 3: Resume / Job Requirement Matching
-- ============================================================================

create table if not exists ml_evaluations (
    evaluation_id uuid primary key default gen_random_uuid(),

    application_id uuid not null
        references applications(application_id)
        on delete cascade,

    requirement_id uuid
        references job_requirements(requirement_id)
        on delete set null,

    matching_score numeric(5,2) not null default 0,

    matching_skills jsonb not null default '[]'::jsonb,

    missing_skills jsonb not null default '[]'::jsonb,

    matched_required_skills jsonb not null default '[]'::jsonb,

    matched_preferred_skills jsonb not null default '[]'::jsonb,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now(),

    constraint ml_evaluations_application_unique
        unique (application_id)
);

create index if not exists idx_ml_evaluations_application
    on ml_evaluations(application_id);

create index if not exists idx_ml_evaluations_score
    on ml_evaluations(matching_score);

alter table ml_evaluations enable row level security;

create policy hr_admin_read_ml_evaluations
on ml_evaluations
for select
using (
    exists (
        select 1
        from users u
        where u.user_id = auth.uid()
        and u.role = 'hr_admin'
    )
);