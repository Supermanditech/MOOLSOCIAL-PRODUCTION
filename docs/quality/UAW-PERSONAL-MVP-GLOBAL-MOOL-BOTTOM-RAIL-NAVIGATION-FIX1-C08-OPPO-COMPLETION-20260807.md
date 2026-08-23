# UAW Personal global Mool navigation C08 OPPO completion

State: `CODEX_OPPO_NAVIGATION_CORE_SATISFIED_FOUNDER_REVIEW_PENDING`

Branch: `remediation/prototype-conformance-2026-07-20`

HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`

Candidate: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C08-DURABLE-HOME-CUMULATIVE-OPPO`

## Customer outcome

Mool now opens one durable Personal home instead of aliasing Social or opening
a popup, modal, temporary ribbon, question/grid launcher or navigation-only
intermediary. The six main actions remain reachable in the persistent root
rail, focused owners expose only valid subactions, and Mool Back/Continue
round-trips preserve the exact supported origin.

## Build and installation

- Profile identity: `1.0.0-r60.8` (`2026080708`).
- APK SHA-256:
  `4B7C7EACA6D141D0ABDD98E33481929D5D6F373EAAFEFA5197C4507FCDF6487B`.
- Exactly one wrapper build and one in-place install were performed.
- Pulled installed APK is byte-identical to the candidate.
- First-install time remains `2026-08-04 02:51:59`.
- No uninstall, data clear, downgrade, second build or second install occurred.

## Host qualification

- Universal: 183 tests, two cycles.
- Buy: 360 passes plus 20 established skips, two cycles.
- Protected Social runtime: 13 tests, two cycles.
- Connected journeys: 99 tests, two cycles.
- Qualified non-golden mobile: 117 files, two complete cycles.
- Formatting: 391 files, zero changes.
- Full static analysis: no issues.
- Thirteen positive machine gates passed.
- Protected accepted-UI, Social and Buy checksum mismatches retain their
  established expected-rejection disposition; no protected baseline changed.

Host completion authority:
`UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C07-HOST-COMPLETION-20260807.md`.

## OPPO qualification

- Six main owners passed with deterministic Back to Mool.
- All 17 projected subactions passed on their visible production owners.
- Social, Buy product, Eat table, Ride Cab, Book Doctor and Work Earn Today
  passed Mool Back and Continue-origin round trips.
- Chat Unread filter, thread and unsent-draft continuity passed.
- Shared Account owner continuity passed.
- Active-subaction retap and internal Back order passed.
- App switch and process-death canonical recovery passed.
- Removed action semantics and rejected Mool launcher wording were absent from
  134 captured OPPO hierarchies.
- Standard OPPO root actions each had a reachable semantic target of at least
  44 px.

Machine summary:
`artifacts/quality/uaw-personal-mvp-global-mool-bottom-rail-navigation-fix1-c08-20260807-01/185-final-oppo-navigation-matrix.log`.

Founder checklist and exact evidence:
`artifacts/quality/uaw-personal-mvp-global-mool-bottom-rail-navigation-fix1-c08-20260807-01/186-final-oppo-device-qualification.md`.

Founder starting frame:
`artifacts/quality/uaw-personal-mvp-global-mool-bottom-rail-navigation-fix1-c08-20260807-01/oppo-u01-u22/183-founder-review-mool-home.png`.

## Bounded holds

- U17 physical offline/error injection was not performed; truthful error/retry
  behavior remains host-qualified.
- OPPO denied shell `WRITE_SETTINGS`, so automated 140% physical font-scale
  mutation was not bypassed or retried. C07 320px/140% host coverage passed
  twice. Founder may perform a manual device text-scale check if desired.
- These holds are explicitly disclosed and are not reported as physical-device
  passes.

## Permanent regression additions

REG-067 through REG-074 were added for artifact-name discovery, helper source
validation, branch-owned native status, IME overlay hit testing, immediate use
of newly registered gates, protected device-setting preflight, and false
device-rejection prevention. All evidence remains retained; false failures are
corrected by additive evidence rather than deleted.

## Founder decision

Review the installed r60.8 candidate from the parked `Your Mool` frame. Accept
or reject the navigation core. If rejected, identify the exact visible frame
and action; a fresh successor identity and machine gate are required for any
new build.
