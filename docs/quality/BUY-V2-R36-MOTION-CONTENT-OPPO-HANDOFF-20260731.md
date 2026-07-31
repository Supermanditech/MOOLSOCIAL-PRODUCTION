# Buy V2 R36 motion, content and OPPO handoff

Date: 31 July 2026

State: `CHECKSUM_MATCHED_FOUNDER_REVIEW_CANDIDATE`

R36 combines `BUY-FV2-074` through `BUY-FV2-085`, the fail-closed
address/order ownership work in `BUY-FV2-117`, and the new review-build
provenance regression in `BUY-FV2-118`. The native Flutter candidate is ready
for connected founder review. Ticket 085 is not closed and no new protected
Buy baseline has been recorded.

## Repository identity and boundaries

- Branch: `remediation/prototype-conformance-2026-07-20`
- Starting and tested HEAD:
  `d5cdfd03543f5d61dcdefba06957c9befee27e8c`
- Local R36 implementation preservation commit:
  `3aa58d13a2384c89567d5c5f5266818dfdc1b5a4`
- R36 app/test source fingerprint:
  `006139205BA4A635EE7AB5FCDFAC8AADFAB97B209E2A0F3AE6267304325C2B0E`
- Existing protected Buy R35.1 tree:
  `f712b5b8ce10dd92b64babc4703379a24918fef5cef9417afe9c6679db79bc5d`
- Protected Social tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`

The R35.1 Buy gate correctly rejects the authorized R36 runtime delta and was
not rewritten. Social, Screens 01–03, the approved HTML screenbook and its
accepted evidence remain unchanged. Backend/API/database behavior was not
invented. Push, deployment, publication and production release remain
unauthorized.

## Candidate implementation

R36 adds or completes:

- one aggregate Shop/Wholesale/Medicine Cart and separated fulfilment review;
- role-specific Mool partner language with licensed-pharmacy facts kept
  separate;
- finite shared motion tokens and zero-duration reduced-motion behavior;
- related Shop, Wholesale, Medicine, Orders, conversion, tracking and service
  themes;
- a crisp code-native M mark with one-time `MoolSocial` recognition and a
  compact resting state;
- restrained pointer-driven depth inside stable commerce bounds;
- replaceable validated product-facts snapshots with approved-catalogue
  fallback;
- established first-party promotion cards;
- fail-closed sponsored and inline-video contracts with zero-height inactive
  slots and no production player/provider;
- unmodifiable address/order projections and explicit stale-selection
  recovery; and
- guarded clean review builds with exact runtime-marker and installed-checksum
  evidence.

## Automated verification

- Full Flutter analysis: passed.
- Focused session/selection/content/motion tests: `41/41` passed.
- Buy screen tests: `66/66` passed.
- Complete Buy regression 1: `148/148` passed; four opt-in evidence generators
  skipped.
- Complete Buy regression 2 against the identical source fingerprint:
  `148/148` passed; the same four generators skipped.
- Before/after source manifests: `Differences=0`.
- Approved UI locks: passed.
- Brand integrity: passed.
- Founder-FINAL Buy reference: passed.
- Protected Social tree: passed with the exact protected hash.
- Interaction contracts: passed.
- Flutter customer-copy gate: passed.
- Nine-state HTML customer-copy gate: passed using a temporary read-only
  server, which was then stopped.
- Buy backend-contract boundary: passed.
- Buy data-egress boundary: passed.

Tests and gates prove deterministic contracts; they do not by themselves
constitute founder or production acceptance.

## Build-provenance regression

The first direct R36 APK had the expected version and checksum but omitted the
device-review runtime defines. It opened sign-in and identified itself as
`unidentified`. A second incremental APK had only an 8,894-byte ZIP payload
delta but 24,305,916 bytes of packaging padding. Both APKs and their diagnoses
remain preserved and are explicitly ineligible.

`BUY-FV2-118` now provides:

- `scripts/build-buy-device-review.ps1`
- `scripts/check-buy-device-review-runtime.ps1`

The supported build path cleans first, supplies the exact review/emulator/
candidate defines, refuses evidence overwrite and records provenance. The
runtime gate rejects an unknown candidate or a runtime that does not reach the
ready authenticated review state. Self-tests proved overwrite refusal and
rejection of the unconfigured installed APK.

## Installed OPPO identity

- Device: OPPO CPH2375
- Serial: `2b3e0f71`
- Package: `com.moolsocial.app`
- Candidate ID: `BUY-R36-MOTION-CONTENT-DEVICE`
- Version: `1.0.0-r36`
- Version code: `2026073146`
- Candidate bytes: `200162740`
- R35.1 byte delta: `24132`
- Candidate APK SHA-256:
  `61797EA0531B5B9AF6C21E684632A9E33095CAAEA678EA26599FC91D9EDD40B5`
- Pulled installed base APK SHA-256:
  `61797EA0531B5B9AF6C21E684632A9E33095CAAEA678EA26599FC91D9EDD40B5`

The guarded runtime-marker gate reached the exact candidate in ready,
setup-complete and authenticated review state.

## Connected replay

The checksum-matched OPPO replay verified:

- Shop first view, responsive search, dense suggestions, filtering, category
  sheet, category selection, product detail and in-cart acknowledgement;
- Wholesale entry, separate search ownership and aggregate Cart addition;
- Medicine entry, separate search ownership, non-prescription addition,
  prescription centre and visible prescription-add success;
- one mixed Cart with Shop `1`, Wholesale `2` and Medicine `1`;
- saved-address reminder and Payment as separate checkout blocks;
- confirmation producing independently owned Shop, Wholesale and Medicine
  orders;
- Orders progress cards, tracking timeline, delivery route, live updates and
  Items;
- Account from a tertiary tracking state and repeat-tap return;
- MoolSocial Assist and repeat-tap return;
- Mool rail without a popup and Buy repeat-tap return; and
- app switch/hot resume without losing the owned Orders state.

Wholesale search for `para` returned no result while Medicine returned
Paracetamol, providing connected evidence that vertical search buckets remain
isolated. Final log inspection found no MoolSocial crash, unhandled Flutter
exception or ANR.

## Founder-supplied video-ad references

Two current Zepto screenshots were pulled read-only from the OPPO and
SHA-256-recorded in:

`artifacts/quality/buy-flutter-r36-motion-content-oppo-20260731-39/founder-reference-zepto-video-ads`

They show a dismissible/muteable/expandable picture-in-picture state and an
explicit full-screen state with sound, close and one CTA. They inform future
MoolSocial placement constraints only. No external brand/content is copied
and no provider, campaign, autoplay, measurement or click-through is
authorized by these references.

## Performance qualification

The source contract caps target frames at 16.667 ms and slow frames at 33 ms,
forbids perpetual motion/audio autoplay and allows no video preload.

Debug-build `gfxinfo` recorded 82 frames, 13.41% jank, p90 23 ms and p95
53 ms while UI automation and evidence capture were active. A controlled
post-reset sample exposed zero Flutter SurfaceView frames, so it was
inconclusive. These raw outputs are preserved and must not be represented as a
release-performance pass. Ticket 084 remains open for profile/release-mode
frame, thermal, memory, battery and interruption qualification on
representative hardware.

## Evidence and remaining gates

Additive evidence:

`artifacts/quality/buy-flutter-r36-motion-content-oppo-20260731-39`

Remaining founder/product gates:

1. Review the connected R36 visual, wording and motion candidate.
2. Accept or reject the role glossary and combined experience.
3. Do not create the next protected Buy baseline until explicit acceptance.
4. Keep paid/video surfaces inactive until provider, campaign, moderation,
   consent, captions/transcript, dismissal/reporting, measurement and
   click-through contracts are approved.
5. Run profile/release performance qualification before production
   acceptance.

No Ticket 085 completion, backend start, protected-baseline update, push,
deployment or publication is implied by this handoff. A local preservation
commit does not imply founder acceptance or production release.
