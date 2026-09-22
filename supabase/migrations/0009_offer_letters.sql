-- =========================================================
-- OFFER LETTERS
--
-- Backs offer_letter_service.py, which was already writing to/reading
-- from this table (client.table("offer_letters")) — the table itself
-- was just never actually created in any prior migration, causing
-- "Could not find the table 'public.offer_letters'" at runtime.
--
-- application_id is UNIQUE (not just a foreign key) because
-- generate_offer_letter() upserts on_conflict="application_id" — one
-- offer letter per application, re-generating replaces the prior one.
-- =========================================================

create table if not exists offer_letters (
    offer_letter_id uuid primary key default gen_random_uuid(),

    application_id uuid not null unique
        references applications(application_id)
        on delete cascade,

    salary text not null,

    joining_date text not null,

    status text not null default 'Generated',

    created_at timestamptz not null default now()
);