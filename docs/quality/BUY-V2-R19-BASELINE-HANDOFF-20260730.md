# Buy V2 R19 native Flutter founder-review baseline handoff

Recorded: 30 July 2026

State: `DEVICE_VERIFIED_FOUNDER_REVIEW_BASELINE`

Founder acceptance remains pending. This is an uncommitted, local production
candidate baseline; it is not a release, deployment, production signing event
or authorization to change the founder-FINAL HTML.

## Why the completed R18 work is recorded as R19

The broad R18 OPPO replay completed the requested Shop, Wholesale, Medicine,
prescription, Cart, Checkout, address, payment, Orders, tracking, scanner,
account and navigation coverage. That exact replay proved one remaining
defect: Save feedback was correctly located near the product interaction but
was still visually too wide.

The evidence was preserved. The smallest correction was made as R19: a compact,
right-anchored, maximum 248 logical-pixel live-region confirmation chip. The
affected suite then passed twice and the exact R19 APK was installed, pulled
back and checksum matched. R19 therefore supersedes R18 only as the corrected
founder-review candidate; R18 remains the complete diagnostic replay record.

## Repository and protected identities

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- Social protected tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- Screens 01–03: protected lock passed
- Founder-FINAL Buy reference: 25 immutable files passed
- Approved HTML screenbook: unchanged and read-only

## Exact candidate and OPPO identity

- Package: `com.moolsocial.app`
- Version: `1.0.0` (`versionCode 2026073019`)
- Device: OPPO CPH2375, Android 13, serial `2b3e0f71`
- Candidate and pulled installed-base SHA-256:
  `99D2032A4D173E13471ABACFD54BE36262F11552D99B8B882CB407723DB183BE`
- Candidate evidence:
  `artifacts/quality/buy-flutter-r19-founder-remediation-oppo-20260730-09`
- Preserved broader R18 replay:
  `artifacts/quality/buy-flutter-r18-founder-remediation-oppo-20260730-08`

## Verification completed against the R19 source state

- Flutter analysis: no issues
- Affected regression run 1: 83/83 passed
- Affected regression run 2: 83/83 passed
- Responsive capture matrix: 64 Android/iOS-size and 140%-text images
- Route interaction contract: 154 unique routes passed
- Customer-copy gate: passed
- Brand integrity: passed
- Approved Screens 01–03 lock: passed
- Protected Social baseline: 119 files and exact tree passed
- OPPO app-scoped runtime log: no matching fatal exception, Flutter error,
  RenderFlex overflow or unhandled exception

The OPPO evidence covers settled Shop, compact product Save feedback, global
account, Orders, live tracking and the native camera scanner on R19. The
preserved R18 replay covers the unchanged Cart, Checkout, address, payment,
Wholesale, Medicine, prescription and manual-scanner journeys.

## Immutable local candidate manifest

`artifacts/quality/buy-flutter-r19-founder-remediation-oppo-20260730-09/BASELINE.json`
pins the exact production and test-source hashes, evidence-manifest hash,
protected-tree hash and APK hash. The earlier
`SHA256SUMS-R19.txt` remains unchanged.

## Boundary after this handoff

- Do not make further subjective Buy UI/UX, layout, branding, colour, motion or
  animation changes until founder review.
- Do not change the approved HTML.
- Do not change Social or its protected tree.
- Do not commit, push, deploy or publish without explicit founder
  authorization.
- Safe follow-on work is limited to proven functional defects, stable tests,
  read-only backend inspection and unambiguous contract boundaries.
