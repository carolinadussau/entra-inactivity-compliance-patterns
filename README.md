# Entra Inactivity Compliance Patterns (C5 Control)

This repository documents a safe, production-oriented approach for implementing
an inactivity control aligned with C5-style compliance requirements.

The focus is on:
- detecting inactive user accounts based on sign-in telemetry
- enforcing a report-and-review model before taking action
- handling exclusions to avoid operational impact
- documenting platform and retention constraints transparently

All identifiers and examples in this repository are synthetic placeholders.
No tenant, customer, or employer data is included.

---

## Control Interpretation

A typical C5-style requirement states that:
- user accounts are locked after a defined period of inactivity
- reactivation requires approval
- long-term inactivity may require full re-provisioning

This project implements the **foundation** of that control:
a daily inactivity detection and reporting mechanism.

Automatic disabling is intentionally out of scope.

---

## What This Project Implements

### Implemented
- Daily CSV report identifying:
  - users inactive beyond a configurable threshold (default: 30 days)
  - users with no sign-in record available in retrieved telemetry
- Report includes:
  - last sign-in timestamp (when available)
  - days since last sign-in
  - user context (UPN, display name, department, accountEnabled, user type)
- Exclusion logic to reduce false positives:
  - unlicensed internal/shared accounts
  - optional external patterns
  - guest users remain in scope

### Not Implemented (by design)
- Automatic disabling of accounts
- Automatic re-enablement workflows
- 60/180-day lookbacks when retention does not support them

---

## Retention and Feasibility

Sign-in data availability via Microsoft Graph is limited by tenant retention.
In practice, this often restricts reliable analysis to ~30 days.

Attempting longer windows (e.g. 60 or 180 days) without extended retention
can result in incomplete or misleading results.

Supporting longer periods requires:
- extended sign-in log retention, and/or
- streaming logs to Log Analytics or a SIEM

This repository documents the validated 30-day approach.

---

## Authentication Patterns

Two app-only authentication approaches are demonstrated:
1) Certificate-based authentication (effective locally, complex in Linux CI)
2) Client secret authentication (CI-friendly), requiring a PSCredential object

The client secret value (not the secret ID) must be used as the credential password.

---

## Files

- `scripts/daily_inactivity_report.ps1`  
  Generates the inactivity report (safe-by-default, no account changes).

- `scripts/connect_graph_client_secret.ps1`  
  Reference snippet showing correct client-secret authentication.

- `cicd/gitlab-ci.example.yml`  
  Example scheduled pipeline configuration (reference only).

---

## Script Layout

- `scripts/daily_inactivity_report.ps1` generates the inactivity report (no destructive actions).
- `scripts/auth/` contains authentication reference patterns (client secret and certificate).
- `scripts/actions/` contains operational scripts:
  - `preview_actions.ps1` is dry-run only
  - `disable_from_report.ps1` requires an explicit `-Execute` flag

## Why This Is Portfolio-Relevant

This project demonstrates:
- validating AI-generated approaches against platform constraints
- designing safe automation boundaries for compliance
- documenting limitations clearly instead of hiding them
- building auditable, review-first workflows

