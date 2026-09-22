-- HRMS Phase 2: email ingestion (Section 6.2) + duplicate detection (Section 6.3)

-- ============================================================
-- email_accounts — connected HR mailbox (Gmail/Outlook OAuth)
-- Tokens are stored encrypted at rest (Section 14); the backend is the
-- only reader (service role), decryption happens in app/services/crypto.py.
-- ============================================================
create type email_provider as enum ('gmail', 'outlook');

create table if not exists email_accounts (
    account_id            uuid primary key default gen_random_uuid(),
    provider               email_provider not null,
    account_email            text not null,
    access_token_encrypted    text,
    refresh_token_encrypted   text not null,
    token_expires_at            timestamptz,
    sync_cursor                  text,  -- Gmail historyId / Graph deltaLink
    connected_by                  uuid references users(user_id),
    is_active                      boolean not null default true,
    created_at                       timestamptz not null default now(),
    updated_at                        timestamptz not null default now()
);

create trigger trg_email_accounts_updated_at
    before update on email_accounts
    for each row execute function set_updated_at();

alter table email_accounts enable row level security;

-- ============================================================
-- applications: additional fields for email-sourced applications
-- and duplicate-detection dashboard flag
-- ============================================================
alter table applications
    add column if not exists email_metadata jsonb,          -- {message_id, subject, from, received_at}
    add column if not exists has_potential_duplicates boolean not null default false;

-- ============================================================
-- duplicate_candidates (Section 6.3)
-- Runs on every new application. HR resolves via Merge / Keep Separate /
-- Mark as Duplicate. No automatic deletion, ever.
-- ============================================================
create type duplicate_match_type as enum ('email', 'phone', 'fuzzy_name');
create type duplicate_resolution as enum ('merge', 'keep_separate', 'mark_duplicate');

create table if not exists duplicate_candidates (
    duplicate_id           uuid primary key default gen_random_uuid(),
    application_id           uuid not null references applications(application_id) on delete cascade,
    matched_application_id     uuid not null references applications(application_id) on delete cascade,
    match_type                   duplicate_match_type not null,
    match_score                    numeric,  -- e.g. fuzzy-name similarity, null for exact email/phone
    status                          text not null default 'pending' check (status in ('pending', 'resolved')),
    resolution                       duplicate_resolution,
    resolved_by                       uuid references users(user_id),
    resolved_at                        timestamptz,
    created_at                           timestamptz not null default now(),
    constraint duplicate_pair_unique unique (application_id, matched_application_id, match_type)
);

create index if not exists idx_duplicate_candidates_status on duplicate_candidates (status);
create index if not exists idx_duplicate_candidates_application on duplicate_candidates (application_id);

alter table duplicate_candidates enable row level security;
