# UAW C30Y FIX5 Flutter JSON event-shape classifier truth completion

Date: 2026-08-15
Ticket: `UAW-C30Y-FIX5-FLUTTER-JSON-EVENT-SHAPE-CLASSIFIER-TRUTH`
Parent: `UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE`
State: source repair complete; fresh post-FIX5 source requalification required

## Outcome

The authoritative Flutter JSON runner no longer directly reads an optional
`type` property under strict mode. It uses one reusable parser, classifies
missing or blank event type without crashing, emits only bounded sanitized
property names, and fails closed if any non-JSON or untyped JSON object remains.

The existing FIX3 evidence binder now accepts the post-FIX5 generation,
requires the FIX5 dual-host sentinel, and binds
`untyped_json_objects=0` in both the retained log and cycle summary. Its
self-test creates a unique current probe manifest and no longer requires a
historical real source manifest to remain current.

## Passed evidence

- PowerShell 7 and Windows PowerShell FIX5 classifier contract passed.
- PowerShell 7 and Windows PowerShell evidence-binder contract passed.
- Full retained Flutter recovery passed with 417 authored passes, 3 declared
  skips, 0 failures, 0 error events, 0 non-JSON lines and 0 untyped JSON
  objects.
- Failed attempt-06 and the first stale-binder self-test remain immutable.

Evidence:

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-reg2194-flutter-recovery-attempt-01.log`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-fix5-classifier-post-binder-pwsh-attempt-01.log`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-fix5-classifier-post-binder-winps-attempt-01.log`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-fix5-binder-post-extension-pwsh-attempt-02.log`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-fix5-binder-post-extension-winps-attempt-02.log`

## Authority boundary

FIX5 authorizes no AAB, upload, activation, install, OPPO mutation, deployment,
provider write or secret access. C30Y release scope is reselected with every
release authority still false and candidate counts still `0/0/0`. Two fresh
complete post-FIX5 source cycles and a current manifest seal are required
before the existing one-AAB authority may become available.
