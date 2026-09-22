-- =========================================================
-- ASSESSMENTS
-- =========================================================

create table if not exists assessments (
    assessment_id uuid primary key default gen_random_uuid(),

    application_id uuid not null
        references applications(application_id)
        on delete cascade,

    position text not null,

    questions jsonb not null default '[]'::jsonb,

    total_questions integer not null default 0,

    pass_threshold numeric(5,2) not null default 70,

    score numeric(5,2),

    result text,

    status text not null default 'Invited',

    started_at timestamptz,

    completed_at timestamptz,

    expires_at timestamptz,

    created_at timestamptz not null default now()
);


-- =========================================================
-- CANDIDATE ASSESSMENT ACCESS
-- =========================================================

create table if not exists assessment_access_tokens (
    access_token_id uuid primary key default gen_random_uuid(),

    assessment_id uuid not null
        references assessments(assessment_id)
        on delete cascade,

    token_hash text not null unique,

    expires_at timestamptz not null,

    used_at timestamptz,

    created_at timestamptz not null default now()
);


-- =========================================================
-- ASSESSMENT RESPONSES
-- =========================================================

create table if not exists assessment_responses (
    response_id uuid primary key default gen_random_uuid(),

    assessment_id uuid not null
        references assessments(assessment_id)
        on delete cascade,

    question_index integer not null,

    selected_option text,

    is_correct boolean,

    locked_at timestamptz,

    created_at timestamptz not null default now(),

    unique (assessment_id, question_index)
);