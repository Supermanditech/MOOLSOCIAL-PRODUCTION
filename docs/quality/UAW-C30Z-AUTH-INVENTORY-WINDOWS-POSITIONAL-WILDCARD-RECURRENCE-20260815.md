# C30Z auth inventory Windows positional-wildcard recurrence

Date: 2026-08-15
Regression: `REG-20260815-2214-C30Z-AUTH-INVENTORY-WINDOWS-POSITIONAL-WILDCARD-RECURRENCE`
Status: resolved; literal-directory inventory exited zero

## Finding

A bounded authentication/navigation inventory passed
`apps/mobile/lib/ui_v2/social/*.dart` as a positional Windows path to ripgrep.
Windows did not expand that wildcard and ripgrep returned an invalid-filename
error after producing partial output from the preceding literal paths. The
partial output is not accepted as a complete Social owner inventory.

## Prevention

Every future Social Dart search passes the existing literal directory
`apps/mobile/lib/ui_v2/social` and places filename selection behind
`--glob '*.dart'`. Every positional path is checked to exist literally before
execution. The failed command is not repeated in the same form.

No source, build, Play, OPPO, provider, credential or external-service state
changed.

## Resolution

The corrected inventory checked each positional owner first, passed the
literal `apps/mobile/lib/ui_v2/social` directory with `--glob '*.dart'`, found
the required authentication and return-routing owners, and exited zero. The
failed partial output remains rejected.
