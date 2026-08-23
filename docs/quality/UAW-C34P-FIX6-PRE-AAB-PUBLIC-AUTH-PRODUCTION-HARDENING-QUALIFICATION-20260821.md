# UAW C34P FIX6 pre-AAB public-auth production hardening qualification

## Outcome

The pre-AAB authentication audit found five production defects. Four executable
source defects are implemented and qualified. Meta application-data erasure is
isolated under FIX7 and blocks public Meta review/production release, but not a
Play-signing bootstrap AAB or developer-role OPPO login testing.

No AAB, Play upload, OPPO install, private login, real email/SMS, provider write,
commit, push or merge occurred during this audit.

## Implemented defects

1. OAuth timeout ordering now has a 45-second backend ceiling, 60-second mobile
   HTTP ceiling and 70-second whole-operation ceiling. A mobile client cannot
   abandon a still-valid backend completion at the old 20-second boundary.
2. X and Instagram attempt expiry is exact: `nowMs >= expiresAtMs` is expired.
3. Only explicit user-denial provider codes map to cancellation. Provider server
   and configuration failures remain sanitized provider failures.
4. Phone verification owns one generation and one terminal callback. Late
   automatic verification, failure, code-sent or timeout callbacks cannot
   silently mutate a completed or superseded request.
5. X and Instagram provider JSON is streamed under a 64-KiB hard cap before
   parsing.

The canonical Android signing path environment owner is
`MOOLSOCIAL_UPLOAD_STORE_FILE`; the stale remembered alias is prohibited.

## Qualification evidence

- whole-mobile `flutter analyze --no-pub`: clean;
- backend typecheck: clean;
- focused backend auth: 40/40 before the extra body-cap tests;
- complete backend suite after all changes: 577/577;
- focused changed mobile suites: 19/19;
- affected authentication/shared gateway suite: 205/205;
- shared C34P gateway: PS7 and Windows PowerShell 5.1 green;
- FIX1A all-eight source gate: PS7 and Windows PowerShell 5.1 green;
- FIX5 provider-preparation gate: PS7 and Windows PowerShell 5.1 green;
- FIX6 pre-AAB hardening gate: PS7 and Windows PowerShell 5.1 green.

## Retained release blocker

`UAW-C34P-FIX7-META-ACCOUNT-DATA-ERASURE` records that current signed Meta
callbacks delete/unlink Firebase Auth identity but do not yet own complete
application-data deletion/anonymization or durable confirmation status. No
destructive product-data behavior will be invented without the exact shared
chat/social retention policy and schema inventory.

## Build boundary

The bootstrap AAB remains held. It may be created only after the canonical
upload-store environment is corrected in the founder-controlled secure build
process and the current build gates are replayed. It is not an OPPO acceptance
candidate. The later final auth AAB must use Play app-signing fingerprints and
rerun final C34L evidence gates.
