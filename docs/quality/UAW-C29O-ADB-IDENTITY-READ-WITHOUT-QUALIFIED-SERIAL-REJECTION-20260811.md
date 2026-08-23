# C29O ADB identity read without qualified serial rejection

Date: 2026-08-11
Ticket context: `UAW-PERSONAL-MVP-SOCIAL-ACTION-TRUTH-AND-ACCESSIBILITY-C29O`

## Rejected attempt

The OPPO read-only audit preflight returned an empty `adb devices -l` list. The
compound command nevertheless continued to package and window identity reads,
which failed with `no devices/emulators found`.

No device, app data, installed package, provider, release or protected evidence
was mutated.

## Permanent prevention

- Device inventory is a dedicated first command.
- Package, activity, screenshot, semantic or input calls begin only after one
  exact authorized serial is present and separately host-qualified.
- Every later device command uses `adb -s <qualified-serial>`.
- An absent or ambiguous device leaves APK comparison pending while source-only
  work continues.
