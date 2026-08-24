# UAW-CURSOR-BUY-SCREEN-SUBACTIONS-UI-20260823

Founder date: 23 August 2026 IST
Lane: `cursor_ui`
Work ID: `buy-screen-subactions-ui-20260823`
Branch: `work/cursor-ui/buy-screen-subactions-ui-20260823`

## Objective

Prepare and implement the founder-directed production UI/UX work for the Buy
screen and its Buy subactions without changing authentication, business logic,
backend contracts, platform configuration, dependencies or release controls.

## Safe start boundary

Cursor may inspect the claimed Buy UI/test owners and produce a concise
current-state/requirement mapping. Cursor must not make a speculative visual or
interaction change until the founder supplies and approves the exact Buy
screen/subaction requirement or reference for the next atomic change.

## Implementation boundary

- Modify only the exact `cursor_ui` owners recorded for this task in
  `config/codex-subagent-coordination-policy.json`.
- Preserve all existing Buy domain/session/service behavior and navigation
  contracts. UI code may consume those contracts but may not redefine them.
- Do not edit authentication, Android/iOS, backend, configuration, scripts,
  dependencies, platform or infrastructure owners.
- Add or update only focused Buy UI/widget tests owned by this ticket.
- One founder-approved UI outcome forms one atomic implementation commit.

## Acceptance

The focused tests pass, the founder approves the exact rendered behavior, the
accepted commit passes the required OPPO journey without regression, sanitized
evidence binds that commit, the evidence-only closure commit is pushed, remote
HEAD equals closure HEAD, and the worktree is clean.

## Founder-accepted installed-runtime baseline — 24 August 2026 IST

Baseline ID: `OPPO-INSTALLED-RUNTIME-BUY-R60-87-20260824`

The founder made the production APK installed on the connected OPPO the
mandatory visual and interaction baseline for this ticket and for subsequent
Cursor/Codex Buy-screen refinement. Older approved references remain historical
traceability only and must not replace this installed-runtime baseline unless a
later founder ticket explicitly says so.

- Installed package: `com.moolsocial.app`
- Installed version: `1.0.0-r60.87` (`versionCode 2026082387`)
- Installed APK SHA-256:
  `EF80600A99FDB9991F7C1763F049863D60F9A9320127FBC179149494757670D8`
- Byte-identical worktree APK:
  `artifacts/quality/uaw-c34p-fix11-google-sign-in-final-r60-87-20260823-01/uaw-c34p-fix11-google-sign-in-oppo-forensic-repair-device-review-release.apk`
- OPPO Photos Shop-screen evidence:
  `artifacts/quality/buy-screen-subactions-ui-20260823/oppo-installed-r60-87-shop-baseline-20260824-112708.jpg`
- Evidence dimensions: `720 × 1612`
- Evidence SHA-256:
  `F486A99F6AA785444949B5CBAD64C8F4D8E3FC480C811F23B512D566B0B07782`

### Authorized ticket delta

Remove the complete animated/video-background Buy header strip immediately
below the system status bar and move the search band plus the complete Buy page
upward into the released space. Retire the obsolete header-only promo, chat and
cart controls, but relocate the required account avatar to the top-right of the
new first row. The avatar must open the existing full-page Account hub and Back
must return to the originating Shop, Wholesale or Orders catalogue. Preserve
the remaining installed-runtime layout, content, navigation, interaction,
accessibility and customer copy unless the founder supplies a later atomic
ticket. Obsolete header-only production code must not remain pending after its
references and focused tests are safely removed or replaced.

### Mandatory no-regression gate

Focused Buy widget coverage must prove that the retired header surface and its
visual-reel semantics are absent; the search band is the first Buy-owned surface
at the top of the safe area for Shop, Wholesale and Orders; a 44 x 44 account
avatar remains at the far right of that row; and the avatar opens Account as a
full-page content surface with a working return path to the originating
catalogue. Any intentional departure from the captured runtime baseline beyond
the authorized delta requires a new founder instruction.

### Parallel OPPO installation safety

The Codex Desktop lane subsequently installed production version
`1.0.0-r60.88` (`versionCode 2026082488`) on the shared OPPO. Its installed APK
SHA-256 was observed read-only as
`673DFCCB9D47D8D68AC26CE073DC98EE2A12E0F0D51345F6542BB1293D36C2DA`.
This Cursor ticket did not build, install, downgrade or overwrite that package.
Device review of this UI delta must use a later consolidated APK after the
independent commits have been integrated by the authorized production owner.

## Cursor implementation evidence — 24 August 2026 IST

- `dart analyze lib/ui_v2/buy/buy_v2_screen.dart`: pass, no issues.
- `flutter test --no-pub test/ui_v2/buy/buy_v2_screen_test.dart`: pass,
  `64/64` tests.
- `flutter test --no-pub test/ui_v2/buy/buy_v2_navigation_motion_test.dart`:
  pass, `8/8` tests.
- Explicit review-capture test
  `OPPO installed baseline header removal review captures`: pass, including
  Shop, Wholesale, Orders and full-page Account.
- OPPO-size review captures are maintained for Shop, Wholesale, Orders and the
  avatar-opened full-page Account surface under
  `apps/mobile/test/ui_v2/buy/candidate_captures/`.
  - Shop SHA-256:
    `C19858CD5FA6DAC8F27FF47E065ECF8D418C8341903E540300A2D6813D060952`
  - Wholesale SHA-256:
    `B96E9F9FE0A75FC8D185BA4BF41159FAFF7CAE00FBDA8EDAADBFB504905B2F11`
  - Orders SHA-256:
    `6EE2BFBCD1FE729BE236F4604202C53FBACB8A2CC36259878BB7D92D1EC55F6B`
  - Account SHA-256:
    `2670DDC6648F65418F8740CA8AA39FB3505FCD021DCE41B502B253D6AE883EE8`
- Production declaration audit: only `_BuyHeader`,
  `_ContextualGlassHeader`, `_HeaderPromoTapTarget`,
  `_HeaderSignatureMotion`, `_HeaderScenePainter`, `_HeaderPromoAction` and
  `_HeaderContextButton` were removed; no non-header Buy type was removed.
- APK build, install and OPPO runtime review remain intentionally unperformed
  until the founder requests the device-test step.
