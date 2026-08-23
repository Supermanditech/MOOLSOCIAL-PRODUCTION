# REG2635 — C33T sanitized AAB absence check used the wrong mobile root

Date: 2026-08-16 IST

## Incident

A pre-launch sanitized diagnostic checked
`mobile/build/app/outputs/bundle/release/app-release.aab` and reported absent.
The repository's real Flutter owner is under `apps/mobile`. The exact real path
still contains the retained rejected C33N r60.52 artifact:

- SHA-256: `E56BF124B3F46D27D34387A5AB6B12012125227095026EAB04CEC56B69A2E8A3`
- bytes: `94797520`

This historical file does not imply a C33T build. C33T's build count and
wrapper invocation count both remained zero.

## Permanent prevention

Sanitized artifact checks must use the exact path owned by the build wrapper:
`apps/mobile/build/app/outputs/bundle/release/app-release.aab`. Any retained
file must be bound by checksum and byte size to its historical candidate state;
file presence alone never creates current-candidate provenance or authority.
