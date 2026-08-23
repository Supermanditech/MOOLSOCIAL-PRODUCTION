# UAW Personal MVP Screen01 R50 provenance and equivalence — C18A disposition

Date: 8 August 2026

State: **REJECTED BEFORE REFERENCE MUTATION — FOUNDER REVIEW AND DEVICE UNLOCK REQUIRED**

## What passed

- sole connected device and installed r60.16 package identity;
- on-device APK SHA-256 identity
  `1CC2A0186CA5DC8C9A09D0B4CC949B94CEE91DE6C70246A4B0168ADE6255150D`;
- brand-integrity machine gate;
- focused analysis of seven Screen01/brand owners;
- shared brand-motion tests, 8/8;
- progressive Screen01 behavior tests, 3/3;
- first-open interruption tests, 4/4; and
- Screen01–03 fitment matrix, 3/3.

## What rejected

The immutable v3 visual suite rejected all three current states:

- normal-motion midpoint: 7.06%, 18,299 pixels;
- slow handoff: 9.45%, 24,494 pixels; and
- recovery: 10.37%, 26,874 pixels.

The current images show the R50 progressive/unified wordmark treatment, while
the protected masters show the earlier v3 composition. No master or current
image was changed.

The installed-device visual replay is also incomplete. The OPPO is connected
but Android reports `deviceLocked=1` and `isKeyguardShowing=true`. The first
asleep capture is black; a later device-side capture produced a zero-byte file.
No credential was accessed or bypassed.

## Required successor decision

The founder must unlock the connected OPPO and review the current normal,
slow-handoff and recovery Screen01 treatment. If all three are accepted, C18B
may freeze them additively as Screen01 v4 and supersede—not overwrite—v3. If
slow or recovery is not accepted, a separately disclosed protected-runtime
correction must combine the accepted R50 normal launch with the applicable v3
state before any new reference can be written.

Until that decision, reference, runtime, build and install writes are closed.
C17F remains rejected and the installed r60.16 predecessor is preserved.

Evidence:

- `docs/quality/UAW-C18A-SCREEN01-V3-THREE-STATE-GOLDEN-DIVERGENCE-REJECTION-20260808.md`
- `docs/quality/UAW-C18A-FIRST-INSTALLED-LAUNCH-CAPTURE-SCREEN-ASLEEP-REJECTION-20260808.md`
- `docs/quality/UAW-C18A-DEVICE-PRECONDITION-SCREENCAP-NONZERO-REJECTION-20260808.md`
- `artifacts/quality/uaw-personal-mvp-screen01-r50-provenance-and-equivalence-fix1-c18a-20260808-01`
