# C30U qualifier ADB devices exit status after pipeline

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Incident

The pre-cycle audit found that the C30U qualifier invoked `adb devices` inside
a pipeline that immediately applied `Select-Object` and `Where-Object`, then
read `$LASTEXITCODE`. A PowerShell pipeline may obscure or replace the native
ADB status, so this code could falsely admit device readiness.

## Root cause

Native output capture, native exit validation and row filtering were combined
in one expression instead of preserving the exit immediately after ADB.

## Prevention

Capture the raw `adb devices` output first, assign the native exit immediately,
reject any nonzero value, and only then filter header/blank lines. Require one
exact `2b3e0f71 device` row. Add a static C30U source assertion forbidding the
old piped invocation before either final cycle.

## Release effect

The latent defect was found before cycle 1 attempt 3. No source manifest, cycle
seal, AAB, upload, Play activation, installation or OPPO mutation occurred;
build/upload/install counts remain `0/0/0`.

## Repair verification

- Qualifier PowerShell parser: passed
- Qualifier SHA-256:
  `91D14475D304A7758B760CD5999823345866A64157F8811F50F597208266F3EF`
- Old piped `adb devices` invocation count: `0`
- Raw ADB capture count: `1`
- Immediate native-exit capture count: `1`
- Post-exit row-filter count: `1`
- Live `adb devices` exit: `0`
- Ready rows: `1`
- Exact `2b3e0f71 device` rows: `1`

The qualifier now fails closed on ADB before row parsing and is eligible for
the final two-cycle run.
