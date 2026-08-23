# UAW C30U cycle 1 attempt 5 user-facing-copy gate rejection

Date: 2026-08-14

Ticket: UAW-C30U post-r60.45 Social repairs and Play Internal acceptance

## Incident

C30U qualifying cycle 1 attempt 5 stopped when
`scripts/check-user-facing-copy.ps1` returned exit 1. The qualifier had already
passed its earlier stages but did not create the accepted source manifest or a
cycle seal.

## Evidence boundary

The immutable failed log is:

`artifacts/quality/uaw-c30u-post-r60-45-social-repairs-play-internal-acceptance-20260813-01/cycle1-attempt-5-check-user-facing-copy.log`

The retained log is 309 bytes and has SHA-256:

`07BEEDF5FAE9238582E57F07247773F9B89871FF443FC6BE5F4B9462F1F0A3D7`

Its exact failure is:

`apps\mobile\lib\features\chat\chat_services.dart:243: prohibited word 'endpoint'`

The Chat URI validator used `ArgumentError.value` with a quoted developer-only
parameter label and a Dev endpoint instruction. Because the exception can be
surfaced outside the validator, this was a production-copy defect rather than a
stale copy-gate expectation.

The repair replaces those internals with one generic configuration-unavailable
error. Focused analysis, 15 Chat tests and the unchanged user-facing-copy gate
pass. An exact no-match-safe membership query proves this Chat owner is not in
the C30U or C29E protected Social baseline, so the existing seal is replayed
unchanged and must not be rewritten.

## Permanent prevention

Hash and preserve the failed log, inspect only its bounded assertion and named
owner, then repair the correct owner truthfully. Do not overwrite attempt-5
evidence, weaken a valid safety requirement or retry qualification before the
root cause is registered and both C30U machine-state owners record the failed
attempt.

No AAB was built or uploaded, no Play release was activated, and the OPPO was
not mutated by this attempt.
