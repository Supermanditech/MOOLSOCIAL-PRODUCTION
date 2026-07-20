# MoolSocial production repository instructions

These instructions are mandatory for every Codex task in this repository.
Repository evidence is the durable source of truth; do not depend on an earlier
chat being available.

## Git and preservation gate

Before any implementation:

1. Run `git status --short --branch`, `git rev-parse --abbrev-ref HEAD` and
   `git rev-parse HEAD`.
2. Work only on `remediation/prototype-conformance-2026-07-20`.
3. Preserve every existing tracked, modified and untracked file. Quality
   screenshots, XML trees, APKs and logs are user-owned evidence.
4. Do not switch, merge, rebase, reset, clean, delete, overwrite or work on
   `main`.
5. `main` remains frozen at `ed2a44d`, tagged
   `baseline-ui-before-conformance-2026-07-20`.
6. Do not commit, push or promote unless the founder explicitly requests it.

If the branch or baseline does not match, stop before writing and report the
exact state.

## Required reading before UI work

Read these files completely, not only their headings:

1. `docs/decisions/ADR-0002-PARALLEL-UI-V2-CONFORMANCE-REBUILD.md`
2. `docs/quality/QA-024-APPROVED-PROTOTYPE-CONFORMANCE.md`
3. `docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`
4. `docs/quality/RELEASE-GATES.md`
5. `docs/traceability/PROTOTYPE-TO-PRODUCTION.md`
6. `docs/quality/CUSTOMER-COPY-MACHINE-GATE.md`
7. `docs/quality/FIRST-OPEN-REAL-USER-STATE-MATRIX.md`
8. `approved-references/manifest.json`
9. `artifacts/quality/screen01-screen03-copy-fitment-20260720/FOUNDER-REVIEW-EVIDENCE.md`
10. `docs/quality/ACTIVE-CODEX-HANDOFF.md`

For delivery planning also read:

- `docs/delivery/45-DAY-GO-LIVE-PLAN.md`
- `docs/delivery/UNIVERSAL-INTENT-PRODUCTION-BACKLOG.md`

Do not treat Flutter goldens, current Flutter behavior or a passing test alone
as approved-prototype authority.

## Required reading before Google Cloud, Firebase or API work

Before any console, CLI, project, billing, authentication, maps, credential,
distribution or environment action, read these files completely:

1. `docs/delivery/ENVIRONMENT-PROMOTION-BOUNDARY.md`
2. `docs/decisions/ADR-0001-GOOGLE-FIRST-AUTOMATED-PLATFORM.md`
3. `docs/delivery/CROSS-PLATFORM-DELIVERY.md`
4. `docs/delivery/APP-IDENTITY.md`
5. `docs/delivery/PRODUCTION-CASCADE-2026-07-20.md`
6. `docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`
7. `docs/quality/ACTIVE-CODEX-HANDOFF.md`

The permanent order is local emulators, `moolsocial-dev-503018` as the
real-service Trial, a screenwise Firebase App Distribution Preview group inside
Dev, clean `moolsocial-staging-503018`, then a later separately authorized
Production project. Preview is not a fourth backend. Never use Production for
experimentation and never enable an API merely because it appears free.

## Mandatory architecture

- Keep one production repository.
- Build the fresh isolated native Flutter UI V2 presentation layer in this
  repository.
- Reuse tested models, sessions/controllers, services, API adapters,
  authentication, Firebase/native configuration, package identity, CI and
  business logic.
- Keep legacy Flutter presentation read-only until complete V2 acceptance.
- Never mix legacy and V2 presentation components.
- Never use HTML inside a Flutter WebView.
- Never partially merge accepted screens into `main`.

## Approved-reference workflow

For each new connected screen or journey:

1. Inspect the existing HTML and every visible state, action, sub-action, tap
   and nested tap.
2. Correct the HTML first.
3. Present the exact requested HTML page and verify pathname, visible heading
   and primary content.
4. Wait for explicit founder `FINAL`.
5. Freeze the accepted HTML, assets, reference images, interaction contract
   and checksums in a new immutable version.
6. Implement the matching isolated native Flutter V2 screen using existing
   non-UI owners.
7. Compare HTML and Flutter at identical viewport, state and text scale.
8. Replay every tap and interruption path on the connected OPPO.
9. Wait for founder `Accepted` or `Rejected`.
10. Preserve accepted checkpoints only on the remediation branch.

Accepted reference versions are never overwritten. A change requires a new
version and a new founder acceptance cycle.

## Immutable Screens 01–03 checkpoint

The following are production accepted and locked:

- Screen 01 `app-splash-first-open` reference `v3`
- Screen 02 `first-setup-language-location` reference `v4`
- Screen 03 `login-account-handoff` reference `v2`

Do not edit their accepted presentation code, HTML, assets, reference images,
contracts, checksums, goldens or locked tests while the next isolated UI set is
developed. Backend/provider configuration may advance only behind the locked
presentation contract. Combining later screens requires a separate integration
replay, not a rewrite of Screens 01–03.

Run `scripts/check-approved-ui-locks.ps1` before and after any work that could
touch their dependency graph.

## Regression and founder-handoff rules

- Never use the founder as the repeated defect-discovery loop.
- Test the complete connected journey, not one screen in isolation.
- Cover clean install, retained data, app switch, calls, lock/unlock, process
  death, permission/settings returns, offline/service failures, invalid input,
  retries, provider returns and authenticated relaunch where relevant.
- Email OTP and mobile OTP are independent paths and must be tested
  independently.
- A review-route failure is not proof that the customer is offline.
- Confirm the exact reviewed APK checksum matches the installed OPPO APK.
- Run affected journeys and two full regressions before candidate promotion.
- Never describe a route into an unapproved legacy screen as production grade.

## Customer-copy machine rule

Customer screens must contain finished, benefit-led product language only.
Never expose implementation notes, examples, prototypes, test language,
technical diagnostics, route/state/source terminology or internal planning
copy. Customer-copy checks must mount every reachable visible state and inspect
rendered text, input labels/hints and semantic labels.

## Evidence and reporting

- Treat `approved-references/manifest.json` as the immutable reference index.
- Treat `artifacts/quality/**` as retained audit evidence; never delete it
  merely because it is untracked or large.
- Reconstruct past activity from Git history, manifests, evidence Markdown,
  test logs, screenshots, XML accessibility trees, candidate manifests and APK
  checksums.
- Keep the active plan explicit. Mark work complete only after the requested
  implementation, proportional verification and founder gate are satisfied.
- At every handoff report branch, HEAD, files changed, checks run, exact
  evidence paths, remaining risks and the next founder decision.
