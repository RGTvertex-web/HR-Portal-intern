-- ============================================================================
-- HRMS: Departments
-- Stores departments available in the recruitment system.
-- ============================================================================

create table if not exists departments (
    department_id uuid primary key default gen_random_uuid(),

    name text not null,

    description text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint departments_name_unique
        unique (name)
);

create index if not exists idx_departments_name
    on departments(name);

create trigger trg_departments_updated_at
    before update on departments
    for each row execute function set_updated_at();

alter table departments enable row level security;

create policy hr_admin_manage_departments
    on departments
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