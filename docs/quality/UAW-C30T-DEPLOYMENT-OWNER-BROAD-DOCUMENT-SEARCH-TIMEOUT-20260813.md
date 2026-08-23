# C30T deployment-owner broad search timeout

Date: 2026-08-13
Regression: `REG-20260813-2009-C30T-DEPLOYMENT-OWNER-BROAD-DOCUMENT-SEARCH-TIMEOUT`

## Incident

Deployment reconciliation recursively searched executable owners together with
the entire historical `docs/quality` corpus for runtime service names. The
command timed out and produced no admissible evidence.

## Permanent prevention

Search exact executable config, scripts and deployment manifests first with
bounded output. Read only specifically named evidence documents returned by
those owners.

This incident grants no AAB, upload, install, deployment, or device authority.
