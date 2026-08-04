# Buy FV2 R56.8 prescription sheet motion handoff

Date: 3 August 2026

State: `TECHNICALLY_DEVICE_QUALIFIED_FOUNDER_REVIEW_PENDING`

## Exact qualified candidate

- Candidate: `BUY-R56-PRESCRIPTION-SHEET-MOTION-FIX2`
- Profile: `1.0.0-r56.8` (`2026080307`)
- Source: 2,400 files,
  `5375B1C77BF52075736AC6E81284AAC9EA083D9550A4EE4A016B2282FD183674`
- APK/install: 133,919,053 bytes, 709 ZIP entries, v2 signed,
  `3E4EB324FC73EA252714054864E62335C02AFB3F7121F60664979D36EBC881E5`
- Device: OPPO CPH2375, serial `2b3e0f71`
- Evidence:
  `artifacts/quality/buy-prescription-sheet-motion-r56-8-fix2-20260803-111`

## Outcome

The existing Account, Medicine, Saved and prescription-gated product callers
share one finite white/navy native prescription sheet. Normal arrival/reverse
are 280/220 ms; reduced motion is zero/static. Close, Back and stale
destination/view/pending-product ownership fail closed. Meera, Arvind and Add
run only after reverse and reuse the existing local prescription session owner.

FIX1 is immutable and device rejected because the existing Medicine caller
promised Upload without an upload implementation. FIX2 changes only that word
to Add and asserts the production caller. No upload, camera, validity,
pharmacist, provider, payment or backend fact is claimed.

Host qualification passes 10 focused tests, four responsive captures, two
266-active/13-skip full Buy regressions and every mandatory gate on unchanged
source. OPPO qualification passes both production callers, all native actions,
Back/Close, lifecycle/process, IME ownership, zero-match failure scan and
presentation p95 26.849 ms.

Technical/device qualification is not founder approval. Founder observation
points are exact in `59-technical-device-qualification-summary.md`. R56.9 is a
separate candidate and must not reuse this APK identity.
