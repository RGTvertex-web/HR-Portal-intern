-- ============================================================================
-- HRMS Phase 3: ML Resume Shortlisting Decisions
-- ============================================================================

create table if not exists shortlisting_decisions (
    decision_id uuid primary key default gen_random_uuid(),

    application_id uuid not null
        references applications(application_id)
        on delete cascade,

    decision text not null
        check (decision in ('shortlisted', 'non_shortlisted')),

    reason text,

    decided_by uuid
        references users(user_id)
        on delete set null,

    decided_at timestamptz not null default now(),

    constraint shortlisting_application_unique
        unique (application_id)
);

create index if not exists idx_shortlisting_application
    on shortlisting_decisions(application_id);

create index if not exists idx_shortlisting_decision
    on shortlisting_decisions(decision);

alter table shortlisting_decisions enable row level security;

create policy hr_admin_manage_shortlisting
on shortlisting_decisions
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