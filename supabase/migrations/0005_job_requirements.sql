-- ============================================================================
-- HRMS: Job Requirements
-- Stores required and preferred skills for each position.
-- ============================================================================

create table if not exists job_requirements (
    requirement_id uuid primary key default gen_random_uuid(),

    department text not null,
    position text not null,

    required_skills jsonb not null default '[]'::jsonb,
    preferred_skills jsonb not null default '[]'::jsonb,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint job_requirements_position_unique
        unique (department, position)
);

create index if not exists idx_job_requirements_position
    on job_requirements(position);

create index if not exists idx_job_requirements_department
    on job_requirements(department);

create trigger trg_job_requirements_updated_at
    before update on job_requirements
    for each row execute function set_updated_at();

alter table job_requirements enable row level security;

create policy hr_admin_manage_job_requirements
    on job_requirements
    for all
    using (
        exists (
            select 1
            from users u
            where u.user_id = auth.uid()
              and u.role = 'hr_admin'
        )
    )
    with check (
        exists (
            select 1
            from users u
            where u.user_id = auth.uid()
              and u.role = 'hr_admin'
        )
    );