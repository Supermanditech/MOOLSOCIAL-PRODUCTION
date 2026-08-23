# REG3078 — release APK could not recover the upload-key alias

- Date: 2026-08-21
- Status: registered before retry
- Candidate: `UAW-C34P-FIX5-ALL-EIGHT-PUBLIC-AUTH-LIVE-PROVIDER-READINESS`

## Incident

The gated release build passed source configuration and compilation, then
failed in `packageRelease` because the founder-entered key password could not
recover alias `moolsocial-upload` from the local JKS. The store itself was
readable, so this is a key-password input mismatch rather than source code,
Firebase or provider failure.

## Impact

- no APK or provenance artifact was produced;
- no OPPO, Play, provider or external state changed;
- no password value was emitted or retained in repository evidence.

## Prevention

Prompt for store and key passwords again in the founder's open shell, validate
both through Java's keystore API using inherited process environment rather
than command-line password arguments, and set build variables only after the
alias key is recoverable.
