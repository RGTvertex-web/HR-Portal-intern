-- HRMS Phase 2: bounce/complaint handling (Section 10)
-- applications.email_bounced / email_bounce_reason already exist (0001).
-- This adds the suppression list itself.

create table if not exists suppression_list (
    email        text primary key,
    reason        text not null,  -- e.g. 'hard_bounce', 'complaint'
    added_at       timestamptz not null default now(),
    cleared_at      timestamptz,
    cleared_by       uuid references users(user_id)
);

alter table suppression_list enable row level security;
