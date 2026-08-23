# REG3089 — r60.79 repeated cold-start recovery without a stage receipt

- Date: 2026-08-21
- Status: candidate rejected; successor builds blocked
- Rejected version: `1.0.0-r60.79+2026082179`

## Incident

r60.79 installed with the exact qualified checksum and no data loss. Its cold
start no longer remained blank, but both early and terminal captures rendered
the same `MoolSocial needs an update` recovery frame. The process remained
alive and fatal/ANR scans were zero.

## Discipline failure

The prebuild machine state required source and widget proof, but allowed the
build before a real installed cold-start receipt existed. The runtime catch
paths also collapsed every bounded stage into one recovery frame without
emitting a sanitized stage identifier. This repeated the customer-visible
r60.77 outcome and prevented root-cause identification from the installed APK.

## Mandatory prevention

- no r60.80 or later build authorization until the r60.79 transition timing is
  measured and the exact failing stage is identified or independently ruled
  out;
- every bootstrap stage emits only a sanitized begin/pass/fail identifier;
- the APK machine contract treats `device_cold_start_receipt=passed` as a hard
  promotion gate, never a pending post-build note;
- rejected APKs and screenshots remain immutable;
- a source/unit pass never substitutes for installed-device startup evidence.
