# UAW AAB C30Y Flutter JSON event missing type crash

Date: 2026-08-15
Regression: `REG-20260815-2194-AAB-C30Y-FLUTTER-JSON-EVENT-MISSING-TYPE-CRASH`
Status: registered before retry

## Finding

Attempt-06 cycle 1 reached the authoritative 59-file Flutter audit, but the
PowerShell runner exited 1 before producing its result summary. Strict mode
rejected direct access to `event.type` on a JSON object that decoded
successfully but did not expose that property.

The failed attempt is preserved and cannot qualify. No AAB, upload, install,
deployment, founder input, credential read or device mutation occurred;
successor action counts remain `0/0/0`.

## Required repair

- Ticket the runner repair inside the existing C30Y release-gate scope.
- Read JSON event type through an optional-property helper.
- Count and classify untyped JSON objects explicitly rather than crashing.
- Add a behavioral gate for typed and untyped reporter objects.
- Reseal source and run two fresh complete cycles before authority returns.

## Resolution

FIX5 added a reusable optional-type/property-name parser and a behavioral gate
that passed under PowerShell 7 and Windows PowerShell. The runner now fails
closed on non-JSON or untyped JSON objects and emits only sanitized property
names, never values. The full retained recovery passed with Flutter 417/3,
zero failures/errors/non-JSON lines, and `untyped_json_objects=0`.

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-reg2194-flutter-recovery-attempt-01.log`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-reg2194-flutter-recovery-attempt-01.exit.txt`
