# C11 adb device-array notmatch header false rejection

- Regression: `REG-20260807-263-C11-ADB-DEVICE-ARRAY-NOTMATCH-HEADER-FALSE-REJECTION`
- Date: 2026-08-07 IST

## Observation

The first install preflight captured `adb devices`, then used array
`-notmatch`. PowerShell returned the nonmatching header line, making the
condition true even though OPPO `2b3e0f71` was connected. The command stopped
before querying the predecessor or executing `adb install`; r60.10 remained
installed and the one install authorization remained unused.

## Permanent correction

After the native exit is checked, device rows are explicitly filtered and the
preflight requires exactly one anchored `2b3e0f71 device` match. Header and
blank lines cannot cause a false rejection. The predecessor version and APK
checksum are revalidated immediately before the still-unconsumed install.
