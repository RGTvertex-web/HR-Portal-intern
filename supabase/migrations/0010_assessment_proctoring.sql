-- =========================================================
-- ASSESSMENT PROCTORING
--
-- Backs the candidate-facing proctoring added to the assessment
-- flow: tab-switch detection, camera-required, and talking/voice
-- detection. Each flagged event is logged here regardless of
-- whether it crosses the auto-submit threshold, so HR has a full
-- record of what happened during any given assessment attempt.
-- =========================================================

create table if not exists assessment_violations (
    violation_id uuid primary key default gen_random_uuid(),

    assessment_id uuid not null
        references assessments(assessment_id)
        on delete cascade,

    violation_type text not null,
    -- expected values: 'tab_switch', 'camera_off', 'voice_detected'

    occurred_at timestamptz not null default now()
);

create index if not exists idx_assessment_violations_assessment_id
    on assessment_violations(assessment_id);


-- =========================================================
-- Records why an assessment ended, when it wasn't a normal
-- candidate-initiated submission (e.g. auto-submitted after
-- repeated proctoring violations). NULL means a normal submit.
-- =========================================================

alter table assessments
    add column if not exists terminated_reason text;