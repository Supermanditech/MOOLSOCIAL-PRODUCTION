# C30T nested ticket projection recurrence

Date: 2026-08-13
Regression: `REG-20260813-2005-C30T-TICKET-NESTED-NULL-PROJECTION-RECURRENCE`

## Incident

Ticket reconciliation enumerated the exact top-level properties, then guessed
fields inside nested `verification`, `resolutionEvidence`, `founderDecision`,
and `authority` owners. The resulting null values are rejected.

## Permanent prevention

Enumerate every exact nested object's properties before accessing its fields.
Top-level schema enumeration does not authorize nested field assumptions.

This incident grants no AAB, upload, install, deployment, or device authority.
