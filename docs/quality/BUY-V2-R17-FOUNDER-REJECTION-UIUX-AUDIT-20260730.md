# Buy V2 r17 founder-rejection and r19 remediation audit

Date: 30 July 2026

Status: r17 rejected; r19 native Flutter remediation implemented and verified;
founder acceptance pending.

## Preserved rejection baseline

The founder rejected r17 even though its automated tests and installed-APK
checksum passed. The exact rejected OPPO state remains under:

`artifacts/quality/buy-flutter-r17-founder-rejection-oppo-20260730-07`

Measured defects included:

- delivery/workspace context bounds `[186,84][608,172]` while Search semantic
  content occupied only `[114,207][302,243]`;
- a near-full-height category surface beginning with
  `[16,114][464,202]`;
- repeated Track and Get help bands in Orders;
- tracking content ending at approximately physical y=1132;
- a quiet Cart icon, inconsistent account handoff, oversized controls and
  unnecessary blank regions.

Those findings became `BUY-FV2-042` through `BUY-FV2-052`.

## Implemented remediation

R19 applies one native Flutter system across Shop, Wholesale, Medicine,
Orders and every tested nested Buy state:

- a distinct MoolSocial brand zone, concise delivery/workspace/pharmacy
  context, dominant Search and persistent account access;
- three catalogue columns at a normal 360 logical-pixel phone width and a
  readable two-column fallback at 320 pixels with 140% text;
- a bounded category chooser that does not resize the product grid;
- compact cards with product, pack, price, delivery, named fulfilment partner,
  partner type, Save and purchase state;
- a reserved, prominent Cart bar with quantity, total and View;
- a compact internal Buy account hub that returns to the exact originating
  Buy depth;
- native camera, barcode and QR scanning with a compact manual fallback and a
  genuine busy state while the scanner opens;
- one support owner, one order action per order, progress percentage and
  compact order facts;
- live tracking with percentage, animated progress, completed/current/next
  steps, route, promise, alerts and useful actions;
- separate saved-address reminder/Edit and payment/Change decisions;
- immediate haptic, selected-state, quantity, notice or real asynchronous
  progress feedback; and
- a compact 248-logical-pixel maximum Save confirmation live region located at
  the catalogue interaction point.

## Verification

- full-app `flutter analyze --fatal-infos`: pass;
- final affected regressions: 83/83 pass twice;
- final responsive matrix: 64 screenshots covering 320x568, 360x800,
  390x844 and 430x932 Android/iOS-size profiles, including 140% text;
- founder-final Buy reference: 25 immutable files pass;
- user-facing copy: pass;
- interaction contracts: 154 unique routes pass;
- approved Screens 01–03 locks and brand integrity: pass;
- protected Social baseline: 119 files and exact tree
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`;
- OPPO CPH2375 installed r19 versionCode `2026073019`;
- candidate and pulled installed-base SHA-256:
  `99D2032A4D173E13471ABACFD54BE36262F11552D99B8B882CB407723DB183BE`;
- app-scoped OPPO log: no fatal exception, Flutter error, RenderFlex,
  overflow or unhandled-exception match.

Final evidence:

`artifacts/quality/buy-flutter-r19-founder-remediation-oppo-20260730-09`

R18 remains preserved separately as the OPPO diagnostic that exposed the
full-width Save-feedback defect. No approved HTML, locked Screen 01–03 source,
protected Social/YouTube source or legacy Buy presentation was changed. No
commit, push, deployment or publication was performed.

Passing verification is not founder visual acceptance.
