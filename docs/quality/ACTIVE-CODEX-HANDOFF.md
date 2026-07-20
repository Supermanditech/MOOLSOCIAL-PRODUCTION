# Active Codex handoff

Snapshot date: 20 July 2026
Purpose: durable context bootstrap for Codex in Android Studio and other Codex
surfaces.

This file does not replace the approved-reference manifest, product-design
memory, QA records or release gates. It points new agents to those authorities
and records the current checkpoint so a missing chat transcript cannot erase
project decisions.

## Workspace boundary

- Authorized workspace: `C:\GUARANTEED OUTCOME`
- Production repository:
  `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Approved HTML screenbook:
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook`
- Folders outside `C:\GUARANTEED OUTCOME` are unrelated and out of scope.

Android Studio Codex was configured with:

- Codex CLI `0.144.6`
- `sandbox_mode = "workspace-write"`
- sole additional writable root `C:\GUARANTEED OUTCOME`
- `openaiDeveloperDocs` MCP
- `moolsocial-workspace` filesystem MCP rooted only at
  `C:\GUARANTEED OUTCOME`

Authentication secrets and desktop-session MCP bridges were not copied.
Android Studio uses its isolated Codex home at
`C:\Users\jisal\AppData\Local\Google\AndroidStudio2026.1.2\aia\codex`.
When validating its MCP list from a terminal, set `CODEX_HOME` to that exact
directory first. Otherwise the executable inherits the desktop Codex profile
and may display unrelated desktop-only connectors that are not part of this
project setup.

## Observed Git state

At this snapshot:

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `b2839b82f5d2164e60df3d89e5ca39e1419acf86`
- Remote branch was two commits behind local HEAD.
- `main`: `ed2a44d`
- Rollback tag: `baseline-ui-before-conformance-2026-07-20`
- Numerous untracked files under `artifacts/quality/**` are retained test
  evidence and must not be cleaned or deleted.

Every new task must verify live Git state rather than assuming this snapshot is
still current.

## Accepted production checkpoint

Founder acceptance evidence:

`artifacts/quality/screen01-screen03-copy-fitment-20260720/FOUNDER-REVIEW-EVIDENCE.md`

Immutable accepted references:

- Screen 01 `v3`
- Screen 02 `v4`
- Screen 03 `v2`

Exact accepted OPPO candidate and installed APK SHA-256:

`76c40d1a3dead71358a72afb77db940f0e9f88751b4a48d958368451d2330ed0`

The accepted journey is:

`Screen 01 → Screen 02 location consent/result → Screen 03 provider or OTP
sign-in → Universal`

Both mobile OTP and email OTP reached Universal. Mobile OTP passed after ADB
reverse mappings were deliberately absent. Authenticated killed-process
relaunch restored Universal.

Screens 01–03 are immutable during development of the next isolated UI set.

## Cloud environment authority

Before any Google Cloud, Firebase, authentication, maps, API, credential or
distribution action, read:

`docs/delivery/ENVIRONMENT-PROMOTION-BOUNDARY.md`

Founder-locked order:

- local Firebase emulators: zero-cost first testing boundary;
- `moolsocial-dev-503018`: separate real-service Trial;
- Firebase App Distribution tester group inside Dev: screenwise Preview;
- `moolsocial-staging-503018`: clean staging for promoted candidates only;
- Production project: created later and never used for experimentation.

Preview is not a fourth backend. An installed client cannot switch
environments at runtime.

Provisioning checkpoint observed 21 July 2026:

- Firebase CLI reauthentication succeeded.
- Billing exists, but Google reports that the completed prepayment may take up
  to 24 hours to be credited.
- The authoritative organisation ID is `1067591230270`; the earlier
  transposed value `1067591730370` must never be reused.
- Direct Organisation Administrator and Project Creator roles are verified for
  the MoolSocial admin principal.
- `moolsocial-dev-503018` now exists inside `moolsocial.com` as Firebase project
  `MoolSocial Dev Trial`, project number `760290687711`, state `ACTIVE`.
- The immediate CLI Firebase attachment returned `403`; project IAM verified
  Owner access, and Firebase console completion then reported the project
  ready. The final state was independently rechecked with Firebase CLI.
- Staging and Production have not been created. Billing and billable APIs have
  not been attached to Dev/Trial.
- Do not create the project outside the organisation as a workaround.
- Do not enable APIs merely because they appear free.
- Do not register Firebase apps or create API/OAuth credentials without the
  applicable action-time confirmation and restriction plan.

## Regression history authorities

Permanent regression decisions are recorded in:

- `docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`
- `docs/quality/QA-024-APPROVED-PROTOTYPE-CONFORMANCE.md`
- `docs/quality/CUSTOMER-COPY-MACHINE-GATE.md`
- `docs/quality/FIRST-OPEN-REAL-USER-STATE-MATRIX.md`
- `docs/quality/RELEASE-GATES.md`

They include the following non-negotiable incidents:

- duplicate/too-fast launch presentation;
- Screen 01 bypassing required Screen 02 after retained state or relaunch;
- incomplete connected-screen testing and regressive founder handoffs;
- opening Screen 02 when the founder requested the exact Screen 03 page;
- customer-visible implementation/example language in OTP and slow-start
  states;
- default-state-only copy tests missing reachable OTP states;
- falsely diagnosing the customer as offline when the device review route
  failed;
- dependency on volatile ADB reverse mappings for mobile OTP.

## Evidence inventory

Retain and consult these directories:

- `artifacts/quality/screen01-oppo-one-visible-final`
- `artifacts/quality/screen01-screen02-oppo-20260720`
- `artifacts/quality/screen01-screen03-copy-fitment-20260720`
- `artifacts/quality/screen02-oppo-interactions-20260720`
- `artifacts/quality/screen02-oppo-v4-20260720-test-candidate`
- `artifacts/quality/screen02-oppo-v4-interruption-matrix-20260720`
- `artifacts/quality/screen02-screen03-combined-20260720`
- `artifacts/quality/screen02-v5-exact-apk-oppo-20260720`

Evidence types include Markdown reports, candidate manifests, PNG captures,
Android XML accessibility trees, filtered logcat, Flutter regression logs,
build logs, PIDs, debug APKs and installed-base APKs. Binary artifacts should
be verified by checksum and appropriate inspection tools, never interpreted as
plain text.

The accepted checkpoint reports:

- HTML customer-copy gate: 9 states passed.
- Phone fitment:
  `320×568`, `360×640`, `360×720`, `375×667`, `390×844`, `412×915`,
  `430×932`, plus compact layout at `140%` text.
- Flutter analyzer: no issues.
- Full regression 1: `375/375`.
- Full regression 2: `375/375`.
- `git diff --check`: passed.
- Physical device: OPPO CPH2375, Android 13, serial `2b3e0f71`.

## Plans

Read and reconcile work against:

- `docs/delivery/45-DAY-GO-LIVE-PLAN.md`
- `docs/delivery/UNIVERSAL-INTENT-PRODUCTION-BACKLOG.md`
- `docs/quality/PRODUCTION-ONLY-SCREEN-READINESS.csv`
- `docs/quality/SCREEN-BY-SCREEN-READINESS.csv`
- `docs/quality/APPROVED-TAP-INVENTORY.csv`

Do not mark a plan item complete from conversation memory. Require repository
evidence and the applicable founder acceptance gate.

## Context reconstruction procedure

At the start of a new Android Studio Codex task:

1. Read `C:\GUARANTEED OUTCOME\AGENTS.md` and the repository `AGENTS.md`.
2. Verify MCP and filesystem access without changing product files.
3. Capture live Git branch, HEAD, status and recent decorated history.
4. Read every required authority listed in the repository `AGENTS.md`.
5. Validate the approved-reference manifest and locked UI script.
6. Inventory existing quality evidence before producing a work plan.
7. Report a context-integrity summary and stop if any branch, checksum,
   reference status or lock differs.

Raw private chat/tool-call transcripts are not automatically shared between
Codex surfaces. Any founder decision that is not already represented in the
repository must be added to the appropriate durable memory, QA, manifest,
evidence or plan file before it can be treated as permanent project history.

## Next founder-authorized UI scope

Founder direction recorded after the context-integrity audit on 20 July 2026:

- Begin the revision/remake of HTML Screen 04,
  `04-universal-focus-shell.html`.
- The authorization covers the Screen 04 HTML review workflow only.
- Inspect every visible state, control, action, sub-action, nested tap and
  connected destination before presenting the corrected HTML.
- Do not modify the production Flutter Screen 04 implementation yet.
- Do not modify locked Screens 01–03 or their accepted references.
- Flutter V2 implementation may begin only after the founder explicitly marks
  the corrected Screen 04 HTML state `FINAL`.

## Screen 04 HTML founder-review candidate — rejected

Durable checkpoint recorded 20 July 2026:

- The founder-authorized Screen 04 HTML remake is present only at
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens\04-universal-focus-shell.html`.
- Founder-rejected candidate SHA-256:
  `9d4bbc76104cb5208f54fdfd83603d89ee563bf0a0cdbb724249f1c27fcd9b86`.
- Exact review URL:
  `http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1`.
- Exact loaded pathname:
  `/screens/04-universal-focus-shell.html`.
- Page heading: `Universal`.
- Customer heading: `What would you like to do?`.
- Default focus: `Social` / `Stay close to what matters.`.
- Visible Universal entries: Social, Buy, Eat, Ride, Book, Pay, Work and Chat.
- `world` focus restoration and `openMool=1` return handling passed.
- Search, scan, voice, notifications, account, permanent serviceable-area and
  Chat return paths were exercised.
- Twenty-six explicit loading, empty, denied, unavailable, failure, retry and
  result moments were mounted and inspected.
- All direct and nested HTML destinations returned HTTP `200`.
- Default and nested controls had no unnamed, dead or sub-44 px control.
- Fitment passed at `320×568`, `390×844`, `430×932` and `390×844` at
  `140%` text with no horizontal overflow or clipped action label.
- Browser console and page-exception lists were empty.
- Screen 04 `git diff --check` and inline JavaScript syntax checks passed.
- The Screen 01–03 approved lock script passed after verification.
- Shared CSS/runtime, Flutter product files, Screens 01–03 and Screens 05 onward
  remain unmodified by the Screen 04 work.

Detailed evidence and the complete control/destination inventory:

`artifacts/quality/screen04-html-founder-review-20260720/SCREEN-04-HTML-FOUNDER-REVIEW-WORKLOG.md`

Current authorization boundary:

- Screen 04 is rejected and authorized for another HTML correction cycle.
- Restore conformance with the approved Universal focus-shell architecture,
  action/sub-action placement, bottom Mool/context/Chat rail and branding.
- Remove visible example, commentary, review, preview and engineering language
  from the entire founder-review page, not only from the simulated phone.
- Read the new permanent regression record in
  `docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`,
  `docs/quality/CUSTOMER-COPY-MACHINE-GATE.md` and issue
  `UI-CONFORMANCE-003` in QA-024 before changing Screen 04 again.
- Do not freeze the candidate or change the approved-reference manifest.
- Do not begin Flutter Screen 04 implementation.
- Do not begin Screen 05.
