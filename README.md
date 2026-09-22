# HRMS — Phase 1 + Phase 2

Foundation build for the HR Recruitment Management System, covering Section 26 Phases 1 and 2:

**Phase 1:** data model, Applications module (website intake, CAPTCHA/rate-limiting, consent
capture, resume upload to private storage), mandatory MFA on HR accounts, dashboard skeleton.

**Phase 2:** email ingestion (Gmail API), duplicate detection (Section 6.3), and bounce/complaint
webhook handling (Section 10).

Nothing past this scope is implemented — no ML shortlisting, no MCQ/AI interview stages, no
offers. Those are separate migrations/routers to add phase by phase, so each phase stays testable
on its own instead of one giant drop.

## What's here

```
supabase/migrations/0001_phase1_init.sql          Schema: users, applications, audit_logs + RLS
supabase/migrations/0002_resume_storage.sql       Private "resumes" Storage bucket (5MB, pdf/doc/docx)
supabase/migrations/0003_phase2_email_and_duplicates.sql
                                                    email_accounts, duplicate_candidates,
                                                    applications.email_metadata / has_potential_duplicates
supabase/migrations/0004_bounce_suppression.sql   suppression_list table

backend/                                           FastAPI service
  app/main.py                                     App entrypoint, CORS, rate-limit handler
  app/auth.py                                     Supabase JWT verification + mandatory MFA (aal2) check
  app/config.py                                   Env-driven settings
  app/database.py                                 Supabase service-role client (backend-only)
  app/routers/applications.py                     POST /applications (public intake), resume upload/view,
                                                    HR list/detail/withdraw
  app/routers/auth_routes.py                      /auth/me, MFA status sync
  app/routers/duplicates.py                       Duplicate-check trigger, list, resolve
  app/routers/email_sync.py                       Gmail OAuth connect/callback, manual sync trigger
  app/routers/webhooks.py                         Bounce/complaint webhook, suppression-list management
  app/services/captcha.py                         Turnstile / reCAPTCHA v3 verification
  app/services/storage.py                         Resume upload + signed URL generation (private bucket)
  app/services/rate_limit.py                      Per-IP (slowapi) + per-email submission caps
  app/services/audit.py                           Append-only audit log writer
  app/services/application_intake.py              Shared insert path (website + email) — triggers
                                                    duplicate check on every new application
  app/services/duplicate_detection.py             Email/phone/fuzzy-name matching (Section 6.3)
  app/services/crypto.py                          Fernet encryption for OAuth tokens at rest
  app/services/gmail_client.py                    Gmail OAuth flow + message/attachment fetching
  app/services/email_parser.py                    Sender/position/department extraction from emails
  app/services/email_intake.py                    Parsed Gmail message → application record
  app/services/oauth_state.py                     Signed state token for the OAuth redirect round-trip
  app/models/                                     Request/response schemas per router

frontend/                                          React (Vite) + Tailwind
  src/pages/ApplyForm.jsx                         Public candidate application form (no account/login),
                                                    resume upload, Turnstile CAPTCHA
  src/pages/Login.jsx                             HR sign-in with mandatory MFA step-up
  src/pages/Dashboard.jsx                         Dashboard skeleton
  src/pages/Applications.jsx                      List, filter by status, view resume, withdraw,
                                                    bounced/duplicate badges
  src/pages/Duplicates.jsx                        Review flagged pairs — merge / keep separate / mark duplicate
  src/pages/EmailSettings.jsx                     Connect Gmail, manual sync, suppression list
  src/components/TurnstileWidget.jsx              Cloudflare Turnstile widget (auto-bypassed in dev)
```

## Setup

### 1. Supabase project

Create a project (use a separate one for staging vs. production per Section 21). Run the
migrations **in order**:

```bash
supabase db push
# or paste each file into the SQL editor, in this order:
#   0001_phase1_init.sql
#   0002_resume_storage.sql
#   0003_phase2_email_and_duplicates.sql
#   0004_bounce_suppression.sql
```

Create your first HR account via Supabase Auth (sign up, then enroll TOTP MFA from the app once
it's running), then promote it to `hr_admin` in SQL:

```sql
insert into users (user_id, email, role, mfa_enabled)
values ('<auth.users.id>', 'you@company.com', 'hr_admin', true);
```

### 2. Backend

```bash
cd backend
cp .env.example .env        # fill in Supabase URL/keys, JWT secret, CAPTCHA config
pip install -r requirements.txt --break-system-packages
uvicorn app.main:app --reload --port 8000
```

`SUPABASE_JWT_SECRET` is under Supabase → Settings → API → JWT Settings. In staging you can leave
`CAPTCHA_PROVIDER=none` to skip real CAPTCHA verification — the frontend widget auto-detects this
and sends a placeholder token instead of trying to render Turnstile.

Leave `EMAIL_SYNC_PROVIDER=none` and Gmail-related env vars blank if you don't want to set up
email ingestion yet — the rest of the app runs fine without it.

### 3. Frontend

```bash
cd frontend
cp .env.example .env        # fill in Supabase URL/anon key, API base URL, (optional) Turnstile site key
npm install
npm run dev
```

Candidate-facing form: `http://localhost:5173/apply`
HR console: `http://localhost:5173/` (redirects to `/login` if not signed in)

### 4. (Optional) Connect Gmail for email ingestion

1. In [Google Cloud Console](https://console.cloud.google.com), create an OAuth 2.0 Client ID
   (type: Web application). Add `http://localhost:8000/email-sync/gmail/callback` as an
   authorized redirect URI.
2. Set `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` in `backend/.env`.
3. Generate an encryption key and set it as `ENCRYPTION_KEY`:
   ```bash
   python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
   ```
4. Restart the backend, go to **Email Tracking** in the HR console, click **Connect Gmail**,
   and grant read-only access. You'll be redirected back automatically.
5. Click **Sync now** to pull recent messages into Applications (`source = EMAIL`).

Periodic auto-polling (instead of the manual "Sync now" button) is a later-phase addition once
Celery/Redis is running — see "What's deliberately stubbed" below.

## Notes on what's deliberately stubbed

- **Per-email rate limit** is in-memory (single process). Fine for now; swap for Redis-backed
  once Celery/Redis is running (already planned for later phases).
- **Resume upload abuse surface**: the upload endpoint is rate-limited per IP and validates
  file type/size, but isn't itself CAPTCHA-gated (Turnstile tokens are single-use, so the same
  token can't cover both the upload and the final submit call). The final `/applications` submit
  is still CAPTCHA-gated, which is what stops spam applications; revisit if upload-only abuse
  shows up in practice.
- **Email sync is manually triggered**, not a background poller. Real periodic ingestion needs
  Celery beat (or a cron job hitting `POST /email-sync/gmail/sync`), which isn't wired up yet —
  the endpoint itself does the real work, it's just not scheduled.
- **Duplicate detection is a full-table scan** per new application (see docstring in
  `duplicate_detection.py`). Fine at Phase 2 volumes; move to indexed normalized columns or
  `pg_trgm` similarity before candidate counts get large.
- **Bounce webhook signature verification** checks a shared-secret header, not SendGrid's actual
  signed-webhook (ECDSA) scheme — a real gap before go-live if SendGrid is the confirmed
  dispatch provider (Section 27 still lists this as open). Flagged in the router's docstring too.
- **Outlook/Microsoft Graph email ingestion** is a stub (`501 Not Implemented`) — Gmail is fully
  built since it's the more common default, but the provider choice itself is still an open
  decision per Section 27.
- **"Merge" duplicate resolution** currently behaves the same as "mark duplicate" — there's no
  child data (assessments, interviews) to reconcile yet since those land in Phase 4+. Once they
  exist, merge should re-point child records onto the canonical application before that write.
- **Interviewer role** exists in the `user_role` enum and RLS is role-aware, but no interviewer
  routes/UI exist yet (that's Section 3's detailed spec, scheduled for Phase 6).

## Next phase

Phase 3 (Section 26): ML resume shortlisting engine, trained on RGTvertex's own labeled
good_intern / bad_intern dataset (Section 15). Add as `0005_*.sql` + new router(s) rather than
editing this drop in place.
