# HR Recruitment Management System

A full-cycle **HR Recruitment Management System (HRMS)** for managing
candidate applications, ML-assisted resume shortlisting, MCQ
assessments, text-based AI interviews, human interviews, offer letters,
offer-response tracking, and onboarding handoff from a single HR portal.

> **Document basis:** HR Recruitment Management System Documentation
> v4.1.\
> **Current implementation:** Own-dataset ML resume scoring + curated
> MCQ/question banks + text-based AI interview flow.\
> **Deferred:** LLM-based question generation/scoring and AI voice/video
> interview input.

------------------------------------------------------------------------

## 📌 Overview

The HR Recruitment Management System extends an automated offer-letter
workflow into a complete recruitment pipeline.

The system is designed around three principles:

1.  **HR remains in control** of recruitment decisions.
2.  **ML provides recommendations**, not automatic hiring/rejection
    decisions.
3.  **Candidates do not need persistent accounts or passwords.**

Candidates apply through the company website or HR email. Shortlisted
candidates receive secure, single-purpose, time-limited links for the
assessment and AI interview.

------------------------------------------------------------------------

## 🚀 Recruitment Pipeline

``` text
Application Received
        ↓
Under Review
        ↓
ML Evaluated
        ↓
Shortlisted / Non-Shortlisted
        ↓
Assessment Invited
        ↓
MCQ Assessment
        ↓
Assessment Passed / Failed
        ↓
AI Interview Invited
        ↓
Text-Based AI Interview
        ↓
HR Review
        ↓
Human Interview
        ↓
Selected / Rejected
        ↓
Final Selected
        ↓
Offer Generated
        ↓
Offer Sent
        ↓
Accepted / Declined / Negotiating / Expired
        ↓
Onboarding Handoff Ready
```

A candidate can be marked **Withdrawn** from any applicable stage before
offer acceptance.

------------------------------------------------------------------------

## ✨ Key Features

### 1. Application Management

-   Website-based application intake
-   Email-based application intake
-   Resume upload and storage
-   Candidate profile parsing
-   Department and position mapping
-   Duplicate candidate detection
-   Consent capture
-   Withdrawn application handling
-   Global search and filtering

### 2. ML Resume Shortlisting

-   Supervised ML resume-scoring model
-   Model trained using the organization's labeled:
    -   `good_intern`
    -   `bad_intern`
-   Training and held-out test split
-   Versioned model
-   Matching skills and missing skills
-   Relevant experience and projects
-   Shortlist recommendation
-   HR override capability
-   Regression testing before model promotion

**Important:** ML does not automatically select or reject candidates. It
provides a recommendation for HR review.

### 3. MCQ Assessment

-   Triggered after shortlisting
-   Secure single-use candidate access link
-   Candidate confirms/uploads resume
-   Candidate verifies and self-rates skills
-   20--30 MCQs selected from curated domain-specific question banks
-   Questions selected according to candidate skills and job
    requirements
-   One question displayed at a time
-   Answer locking
-   No back navigation
-   Configurable pass threshold
-   Instant Pass/Fail calculation
-   HR can override the result
-   Candidate sees only the outcome, not the raw score

### 4. Text-Based AI Interview

-   Separate secure access token
-   4--5 domain-relevant interview questions
-   Questions selected from curated domain/question templates
-   Resume/domain-aware question selection
-   Text-answer submission
-   Full transcript stored
-   HR review and evaluation
-   Answers are not used for automatic rejection

> LLM-based dynamic question generation, answer scoring, aggregate AI
> scoring, and AI reasoning are deferred and are **not part of the
> current implementation**.

### 5. Human Interview Management

-   Multi-round interviews
-   Interviewer assignment
-   Calendar integration
-   Attendance tracking
-   Interview evaluation
-   Technical evaluation
-   Communication evaluation
-   Problem-solving evaluation
-   Project knowledge evaluation
-   Confidence evaluation
-   Selected/Rejected decision
-   Interviewer reschedule request

### 6. Offer Letter Management

-   Offer generation
-   HTML-to-PDF offer generation
-   Versioned offer templates
-   Offer preview/history
-   Email dispatch
-   Offer expiry
-   Accept / Decline / Negotiate / Expired tracking
-   Offer reminders

### 7. Onboarding Handoff

-   Trigger onboarding handoff after offer acceptance
-   Document checklist
-   IT provisioning request tracking
-   HRIS/manual handoff status

### 8. Email & Communication

Versioned candidate communication templates include: - Application
acknowledgment - Assessment invitation - Assessment result - AI
interview invitation - Interview invitation - Interview reminder -
Interview reschedule notice - Rejection - Offer letter - Offer
reminder - Withdrawal confirmation

### 9. Email Bounce Handling

-   Bounce webhook
-   Hard-bounce detection
-   Candidate email-bounced flag
-   Failure reason tracking
-   HR notification
-   Suppression list
-   Manual correction before sending again

### 10. Reporting & Audit

-   Dashboard analytics
-   Department-wise reports
-   Position-wise reports
-   CSV/Excel exports
-   Audit logs
-   Candidate data access requests
-   Erasure workflow
-   Retention management

------------------------------------------------------------------------

## 👥 User Roles

### HR / Admin

Full access to: - Applications - ML evaluation - Assessments - AI
interviews - Human interviews - Offers - Dashboard - Reports - Exports -
Notifications - Audit logs - Settings

Authentication uses **Supabase Auth with mandatory MFA**.

### Interviewer

Restricted access to assigned interviews only.

Can: - View assigned candidate information - View relevant
resume/application information - Mark attendance - Submit evaluation -
Add notes - Submit Selected/Rejected decision - Request rescheduling

Cannot: - Browse all applications - View other candidates - View offer
information - View salary/stipend information - Reschedule directly

### Candidate

Candidates: - Do not create persistent accounts - Apply through
website/email - Receive stage-specific email links - Use secure,
time-limited links for assessment and AI interview

------------------------------------------------------------------------

## 🏗️ Architecture

``` text
                 ┌──────────────────────┐
                 │   Company Website    │
                 │   Application Form   │
                 └──────────┬───────────┘
                            │
                            ▼
┌────────────────┐   ┌──────────────────────┐   ┌─────────────────┐
│ HR Mailbox     │──▶│    FastAPI Backend   │◀──│ HR Web Portal   │
│ Gmail/Outlook  │   │                      │   │ React + Vite    │
└────────────────┘   │ Business Logic       │   └─────────────────┘
                     │ ML Processing        │
┌────────────────┐   │ Assessment Engine    │
│ Google/Outlook │──▶│ Interview Engine     │
│ Calendar       │   │ Email/PDF Services   │
└────────────────┘   └──────────┬───────────┘
                                │
                     ┌──────────▼──────────┐
                     │      Supabase       │
                     │ PostgreSQL + Auth   │
                     │ Storage              │
                     └─────────────────────┘
```

### Architectural Principles

-   Frontend never directly accesses external APIs.
-   FastAPI is the backend integration layer.
-   Supabase is the source of truth for candidate/application data.
-   ML processing runs asynchronously.
-   PDF generation and email dispatch are decoupled and retryable.
-   Candidate emails use versioned templates.
-   Staging and production environments are isolated.

------------------------------------------------------------------------

## 🛠️ Technology Stack

  Layer               Technology
  ------------------- ------------------------------------------------
  Frontend            React + Vite
  UI                  Tailwind CSS
  Backend             FastAPI / Python
  Database            Supabase PostgreSQL
  File Storage        Supabase Storage
  HR Authentication   Supabase Auth + JWT + MFA
  Candidate Access    Signed single-use JWT tokens
  ML                  Python + scikit-learn / supervised ML pipeline
  Background Jobs     Celery + Redis
  Email Ingestion     Gmail API / Microsoft Graph
  Email Dispatch      SMTP / Gmail API / SendGrid
  PDF Generation      WeasyPrint / Playwright
  Calendar            Google Calendar API / Microsoft Graph
  CAPTCHA             Cloudflare Turnstile / reCAPTCHA v3
  Monitoring          Sentry + Uptime Monitoring
  CI/CD               GitHub Actions

------------------------------------------------------------------------

## 🤖 ML Resume Scoring

The active resume model is trained specifically on the organization's
labeled dataset.

### Dataset Labels

``` text
good_intern
bad_intern
```

### ML Workflow

``` text
Labeled Resume Dataset
        ↓
Data Preparation
        ↓
Training Split
        ↓
Model Training
        ↓
Held-Out Test Split
        ↓
Model Validation
        ↓
Save / Version Model
        ↓
Resume Scoring
        ↓
HR Shortlisting Recommendation
```

The model uses job-relevant information such as: - Skills - Education -
Experience - Projects - Profile links

Sensitive/protected personal characteristics are excluded.

The result should remain explainable through: - Matching skills -
Missing skills - Relevant experience - Relevant projects - Match
score/probability - Recommendation

------------------------------------------------------------------------

## 📝 MCQ Assessment Flow

``` text
HR Shortlists Candidate
        ↓
Assessment Invited
        ↓
Email Secure Assessment Link
        ↓
Candidate Opens Link
        ↓
Resume Confirmation
        ↓
Skill Self-Rating
        ↓
Save & Verify
        ↓
MCQs Loaded from Domain Question Bank
        ↓
One Question at a Time
        ↓
Answer Locked
        ↓
Assessment Submitted
        ↓
Pass/Fail Computed
        ↓
HR Review / Override
```

The current design uses deterministic scoring against a configurable
position-level threshold.

------------------------------------------------------------------------

## 💬 Text Interview Flow

``` text
Assessment Passed
        ↓
AI Interview Invited
        ↓
Email Secure Interview Link
        ↓
Candidate Confirms Resume
        ↓
4–5 Domain Questions
        ↓
Candidate Submits Text Answers
        ↓
Answers Stored
        ↓
HR Reviews Transcript
        ↓
HR Evaluation
        ↓
Human Interview Scheduling
```

The current implementation does **not** use an LLM to score the
candidate.

------------------------------------------------------------------------

## 🔐 Security

The system includes:

-   HR-only authenticated routes
-   Role-based access control
-   Mandatory HR/Admin MFA
-   API rate limiting
-   JWT session expiry
-   Refresh-token policy
-   Private Supabase Storage buckets
-   Signed URLs for resumes/PDFs
-   Server-side encrypted API credentials
-   Input validation and sanitization
-   File type/size validation
-   CAPTCHA protection
-   Audit logging
-   Append-only audit records
-   Single-use candidate tokens

### Candidate Token Security

Assessment and AI interview tokens are: - Cryptographically signed -
Single-use - Stage-specific - Candidate-specific - Time-limited -
Invalidated after submission

Default TTL is **72 hours**, configurable by the system.

------------------------------------------------------------------------

## 🗄️ Main Database Tables

Key tables include:

``` text
applications
job_requirements
ml_evaluations
shortlisting_decisions
assessments
assessment_responses
ai_interviews
ai_interview_evaluations
candidate_access_tokens
interviews
interview_evaluations
offers
offer_templates
onboarding_handoffs
email_logs
audit_logs
users
data_access_requests
```

------------------------------------------------------------------------

## 🔌 Important API Endpoints

### Applications

``` http
GET    /applications
GET    /applications/{id}
POST   /applications/{id}/duplicate-check
POST   /applications/{id}/withdraw
POST   /applications/bulk-action
```

### ML

``` http
POST   /ml/shortlist/{position_id}
POST   /applications/{id}/shortlist-decision
```

### Assessments

``` http
POST   /assessments/{application_id}/generate
POST   /assessments/{id}/token
GET    /assessments/access/{token}
POST   /assessments/access/{token}/answer
POST   /assessments/access/{token}/submit
GET    /assessments
POST   /assessments/{id}/override
```

### AI Interviews

``` http
POST   /ai-interviews/{application_id}/generate
POST   /ai-interviews/{id}/token
GET    /ai-interviews/access/{token}
POST   /ai-interviews/access/{token}/answer
POST   /ai-interviews/access/{token}/submit
GET    /ai-interviews
```

### Human Interviews

``` http
POST   /interviews
POST   /interviews/{id}/reschedule
POST   /interviews/{id}/flag-reschedule
PATCH  /interviews/{id}/attendance
POST   /interviews/{id}/evaluation
```

### Offers

``` http
POST   /final-selection/{application_id}
POST   /offers
POST   /offers/{id}/send
POST   /offers/{id}/response
GET    /offers
POST   /offers/{id}/onboarding-handoff
```

### Reporting / Compliance

``` http
GET    /dashboard
GET    /dashboard/{department}
GET    /audit-logs
GET    /export/{resource}
POST   /data-access-requests
POST   /data-access-requests/{id}/fulfill
```

------------------------------------------------------------------------

## 📊 Performance Targets

  Operation                                                           Target
  ----------------------------------- --------------------------------------
  Resume parsing                                       \< 10 sec/application
  ML shortlisting                                  \< 3 min / 100 candidates
  MCQ question selection                                 \< 15 sec/candidate
  Text interview question selection                      \< 15 sec/candidate
  PDF offer generation                                              \< 5 sec
  Email dispatch enqueue                                           \< 15 sec
  Dashboard load                        \< 2 sec on cached/materialized view
  CSV/Excel export                            \< 30 sec for up to 5,000 rows

These are initial design targets and should be validated against real
infrastructure before production sign-off.

------------------------------------------------------------------------

## 🧪 Testing Strategy

The project should include:

### Unit Testing

Test: - ML scoring logic - MCQ question selection - MCQ scoring -
Interview question selection - Text-answer flow - PDF generation - Email
services - Status transitions

### Integration Testing

Test the complete flow:

``` text
Application
 → ML Shortlisting
 → Assessment
 → AI Interview
 → Human Interview
 → Offer
 → Offer Response
```

### ML Regression Testing

A fixed, versioned regression set derived from the organization's
labeled resume dataset should be rerun whenever: - ML model changes -
Feature processing changes - Scoring logic changes

### UAT

Each implementation phase requires HR sign-off in staging.

------------------------------------------------------------------------

## 🌍 Environments

Two isolated environments are recommended:

### Staging

-   Separate Supabase project
-   Separate database
-   Separate storage
-   Test/sandbox email identity
-   Seeded/anonymized data
-   Used for QA/UAT

### Production

-   Separate Supabase project
-   Production database/storage/auth
-   Real email delivery
-   Tagged releases only

### Release Flow

``` text
Feature Branch
      ↓
Pull Request
      ↓
develop
      ↓
Staging Deployment
      ↓
QA / UAT
      ↓
Tagged Release
      ↓
main
      ↓
Production
```

------------------------------------------------------------------------

## 🗺️ Implementation Phases

  -----------------------------------------------------------------------
  Phase                               Scope
  ----------------------------------- -----------------------------------
  1                                   Supabase data model, applications,
                                      CAPTCHA, consent, MFA, dashboard

  2                                   Email ingestion, duplicate
                                      detection, bounce handling

  3                                   Job requirements + own-dataset ML
                                      resume shortlisting

  4                                   MCQ assessment engine

  5                                   Text interview engine

  6                                   Human interviews, calendar sync,
                                      interviewer permissions

  7                                   Final selection + offer generation

  8                                   Offer response, email tracking,
                                      notifications, audit logs

  9                                   Onboarding handoff, withdrawal,
                                      search/filter, mobile
                                      responsiveness

  10                                  Reporting, exports, retention,
                                      access/erasure, monitoring

  11                                  Security hardening, QA, UAT,
                                      backup/DR drill, go-live
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## ⚠️ Current Scope vs Future Scope

### Implement Now

-   Own-dataset ML resume scoring
-   ML model training/testing/versioning
-   Curated MCQ question banks
-   Deterministic MCQ Pass/Fail
-   Secure assessment links
-   Curated text interview questions
-   Text-based candidate answers
-   HR review of interview answers
-   Human interview management
-   Offer generation
-   Email communication
-   Audit and reporting

### Deferred

-   LLM-generated MCQs
-   LLM-generated interview questions
-   LLM answer scoring
-   Aggregate AI interview score
-   AI-generated reasoning
-   LLM prompt regression testing
-   AI voice/video interview input

The system should remain fully functional without an LLM.

------------------------------------------------------------------------

## 📱 Responsive Design

The HR portal should support: - Desktop - Laptop - Tablet - Mobile

Candidate assessment and interview pages must be mobile-friendly because
candidates may open secure links directly from email on their phones.

------------------------------------------------------------------------

## 📋 Important Open Decisions

Before production launch, stakeholders should confirm:

-   Gmail vs Outlook for HR mailbox
-   Google Calendar vs Outlook Calendar
-   Whether Interviewer role is required at launch
-   Rejected-candidate retention period
-   Offer negotiation data structure
-   Onboarding destination/HRIS
-   Number of offer template variants
-   Performance targets
-   Future inbound email reply parsing
-   Legal approval for DPDP consent/retention language
-   MCQ overall time limit
-   MCQ pass threshold policy
-   Candidate token TTL
-   Future LLM provider, if LLM functionality is later approved

------------------------------------------------------------------------

## 🔮 Future Enhancements

Potential future improvements include:

-   Optional AI voice/video interview
-   Candidate composite scorecard
-   MCQ anti-cheating signals
-   Position-level configurable pipeline stages
-   Interviewer self-service availability
-   Candidate feedback/NPS
-   Employee referral tracking
-   Slack/Teams HR notifications
-   Multi-language support
-   Offer-template A/B testing
-   HRIS integration

------------------------------------------------------------------------

## 📄 Project Documentation

This README is based on:

**HR Recruitment Management System Documentation --- Version 4.1**

The documentation defines the system architecture, actors, modules, data
model, APIs, security model, ML approach, assessment/interview flow,
testing strategy, implementation phases, and future enhancements.

------------------------------------------------------------------------

## 👨‍💻 Development Notes

When implementing the project:

1.  Keep HR/Admin and Interviewer permissions strictly separated.
2.  Never expose candidate private files through public URLs.
3.  Never treat the ML recommendation as an automatic hiring decision.
4.  Keep candidate access token-based rather than creating persistent
    candidate accounts.
5.  Keep MCQ scoring deterministic.
6.  Keep text interview answers available for HR review.
7.  Do not implement deferred LLM/voice-video functionality unless the
    scope is explicitly updated.
8.  Version both the ML model and important templates.
9.  Log important state changes and HR overrides.
10. Validate all changes in staging before production deployment.

------------------------------------------------------------------------

## 📌 Status

**Project:** HR Recruitment Management System\
**Documentation Version:** 4.1\
**Primary Users:** HR/Admin, Interviewers\
**Candidate Authentication:** Secure token links, no persistent login\
**ML:** Own labeled dataset (`good_intern` / `bad_intern`)\
**Assessment:** Curated MCQ question banks\
**AI Interview:** Text-based, curated domain questions\
**LLM:** Deferred\
**Voice/Video:** Deferred\
**Production readiness:** Requires phased implementation, QA/UAT,
security hardening, and stakeholder sign-off
