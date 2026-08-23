# MoolSocial production repository instructions

These instructions are mandatory for every Codex task in this repository.
Repository evidence is the durable source of truth; do not depend on an earlier
chat being available.

## Git and preservation gate

Before any implementation:

1. Run `git rev-parse --abbrev-ref HEAD` and `git rev-parse HEAD` as independent
   scalar commands. This repository has a known-large preserved dirty tree: do
   **not** emit full `git status --short --branch`. Prove preservation with a
   non-emitting `git status --porcelain=v1 -z` byte/count/SHA digest, project the
   branch header alone when needed, and emit status only for the task's literal
   assigned owners.
   Suppress every helper/async return value; the digest output allowlist is
   exactly bytes, records, SHA-256, stderr bytes and exit code.
2. Keep the production checkout on
   `remediation/prototype-conformance-2026-07-20`. Feature work may use only a
   primary-created isolated worktree and task branch admitted by the mandatory
   Codex/Cursor production Git discipline below; never switch the production
   checkout to a feature or integration branch.
3. Preserve every existing tracked, modified and untracked file. Quality
   screenshots, XML trees, APKs and logs are user-owned evidence.
4. Do not switch, merge, rebase, reset, clean, delete, overwrite or work on
   `main`.
5. `main` remains frozen at `ed2a44d`, tagged
   `baseline-ui-before-conformance-2026-07-20`.
6. Do not commit, push or promote unless the founder explicitly requests it.

If the branch or baseline does not match, stop before writing and report the
exact state.

## Mandatory Codex/Cursor isolated production Git discipline

The accepted Google-auth runtime baseline remains commit
`f105195ba505dcc9f25a35ab64aab104dadb47c2` and annotated tag
`moolsocial-google-auth-r60.87-accepted-20260823`. Parallel work begins only
from the annotated governance tag
`moolsocial-parallel-production-discipline-20260823-v4` after the founder
explicitly authorizes its commit/tag/push.

Before that work-start tag is created, the primary must pass
`governance_preflight`. It proves the production checkout descends from the
accepted r60.87 commit, has no post-baseline merge commit, is secret-safe and
has zero staged, unstaged or untracked files. Every worktree registered to this
repository must also use an authorized path and be clean. A dirty checkout or
legacy worktree cannot become the governance baseline. Existing user evidence
is classified and preserved; it is never deleted to force this gate green.

- Parallel mutation in one checkout is forbidden. The production checkout is
  coordination-only while feature work is active. Cursor, Codex and later
  integration each use a different Git worktree created directly under
  `C:\GUARANTEED OUTCOME`; a replacement clone or repository is forbidden.
- The retired legacy worktree path
  `C:\GUARANTEED OUTCOME\MOOLSOCIAL-WORKTREES\codex-cursor-baseline-reconciliation`
  is preserved outside the active worktree estate and is forbidden as a
  Cursor, Codex or integration starting point. The primary creates a new
  authorized worktree from the clean governance tag only after the founder
  assigns the exact ticket.
- Every worktree has one founder-authorized ticket, short work ID, exact lane,
  exact branch, exact active owner claim and current regression generation.
  Run `scripts/check-codex-subagent-coordination-policy.ps1` with the matching
  `-ProductionLane` and `-ProductionPhase` before any task action and at every
  handoff boundary.
- `cursor_ui` may edit only its exact UI/UX and focused-test owners. It may not
  edit authentication, Android/iOS configuration, backend, dependency,
  release, baseline, policy or locked Screen 01-03 owners.
- `codex_auth` may edit only its exact provider/authentication owners and may
  not edit unrelated UI/UX. It is independent of `cursor_ui` only while their
  owner claims remain disjoint.
- Cursor may hold at most one open UI/UX ticket, and Codex may hold at most one
  open authentication-provider ticket. Codex handles email link, Facebook,
  Instagram, YouTube Connect and X as separate founder-selected tickets, one at
  a time. Neither agent may accept its next ticket until `ticket_close` proves
  the prior branch is accepted, clean and equal to its remote readback.
- `codex_backend` for a Cursor-designed journey is blocked until the founder
  accepts the exact Cursor UI commit and a repository evidence file binds that
  commit, the interaction/business contract and their SHA-256 values. Backend
  work starts from that accepted UI commit, never from an unaccepted screen.
- Feature commits are small, ticket-scoped and atomic. Their subjects use the
  lane/work-ID form enforced by the machine gate. Feature branches contain no
  merge commits and no changed owner outside the recorded claim.
- After the governance baseline exists, zero Git dirt is mandatory at every
  task start, handoff, founder acceptance, OPPO acceptance, ticket close,
  integration boundary and promotion boundary. Each Cursor or Codex agent owns
  the cleanliness of its own worktree: no staged, unstaged or untracked source,
  test, evidence or generated file may remain when a ticket is accepted or
  closed. Required non-secret source/evidence is tracked; local secure inputs
  live outside the repository or are safely ignored. User evidence is never
  deleted merely to obtain a clean status.
- A ticket is not Git-complete from chat approval or local tests alone. The
  gate requires the exact accepted implementation commit, followed by one
  evidence-only closure commit whose sole parent is that accepted commit and
  whose only changed owners are the SHA-256-bound founder requirement evidence
  and successful OPPO evidence. It additionally requires a clean worktree,
  secret safety, atomic history and an exact `origin` branch readback equal to
  the closure HEAD. The responsible agent must run both `ticket_acceptance` and
  `ticket_close` phases and may not begin another ticket while either remains
  incomplete.
- Rebase, squash, force-push, history rewriting, direct feature-to-production
  merging and direct work on `main` are forbidden. A separate integration
  branch/worktree starts from the governance tag, accepts only exact approved
  feature commit SHAs through `--no-ff` merge commits and contains no direct
  source commit.
- Integration must be clean and must pass changed-owner, secret, dependency,
  source, focused, combined-regression and release preflight gates before one
  uniquely versioned candidate can be authorized. Founder screen acceptance,
  host tests and real-device/provider acceptance remain distinct gates.
- The primary integration owner is accountable for Git closure across the
  whole batch. Before integration and candidate authority, every registered
  MoolSocial production/Cursor/Codex/integration worktree must be clean, each
  accepted feature branch must exist on `origin` at its exact approved SHA,
  and the integration branch must close cleanly on `origin`. Conflict edits,
  untracked leftovers, stale remote refs and abandoned dirty worktrees block
  consolidation. Clean feature worktrees may be removed only after their exact
  commits are integrated and remotely verified.
- Promotion occurs only after founder acceptance through a separately
  authorized curated update of the remediation branch and a new annotated
  acceptance tag. `main` remains frozen.

## Mandatory subagent coordination gate

Every primary agent and subagent must completely read
`docs/quality/CODEX-SUBAGENT-MANDATORY-COORDINATION-POLICY-20260818.md` and
`config/codex-subagent-coordination-policy.json` before any repository action
beyond mandatory reconstruction. Then run
`scripts/check-codex-subagent-coordination-policy.ps1` with the canonical task
name, role, exact recorded owner claim and current registry count/SHA. No edit,
parser, test, build, browser, device or external action may precede that pass.

- Only the primary agent allocates regression numbers, appends or corrects the
  registry, edits the active handoff/policy/owner claims, resolves overlaps and
  authorizes a stopped agent to retry.
- A subagent reports the exact incident and stops. It never guesses a REG ID,
  writes the registry, performs a later diagnostic or resumes without the
  primary-provided literal ID/path and refreshed memory/policy generation.
- Each active task has one case-insensitive, canonical repository-relative
  owner claim. Editing an unclaimed, shared or primary-only owner is blocked.
- Registry movement invalidates pending mutations/tests and bound readiness
  pins. The primary freezes registry writers during final pin/self-test.
- One owner is patched per bounded operation and read back before the next;
  broad heterogeneous propagation patches are prohibited.
- Full session/exit metadata is mandatory for commands that may yield. Output
  truncation, semantic incompleteness, outage ambiguity and orphan recovery are
  stop conditions.
- Real seal, cycle, build, Play, OPPO, browser/provider, authentication,
  private/account, SMS/email and other external actions have one primary
  coordinator and may never run in parallel.

The machine gate must reject duplicate full registry IDs, duplicate numeric
prefixes, duplicate tasks, overlapping owner claims, primary-only subagent
claims, stale registry generation, missing mandatory reads and branch/HEAD
drift. These requirements apply to every future task, not only C34L.

For `docs/quality/ACTIVE-CODEX-HANDOFF.md`, discover only the first two `^## `
heading line numbers without emitting content. The current checkpoint is lines
1 through one-before-the-second-heading; read only that range in independent
non-overlapping pages of at most 250 lines. Never raw-read the full append-only
handoff.

For the large `config/mvp-scope-gate-state.json`, parse without emitting the
full owner. Project exact identity metadata, root property names and only the
current state/ticket/disclosure/authorization/execution/checkpoint/provider
subtrees; read a named historical subtree only when required. Never raw-read
or fully emit the complete MVP scope state.
Within `preTicketSelectionCheckpoint`, project only `checkpointId`, `path`,
`sha256`, `state`, `currentTicketId` and exact `selectedTicketAssessment`;
never enumerate all historical assessment properties.

## Founder-directed MVP scope gate

- All successor tickets, scope expansions, runtime/backend writes, builds,
  device installs and external-service actions must follow
  `docs/delivery/MVP-SCOPE-EXECUTION-POLICY.md` and
  `config/mvp-scope-policy.json`.
- Before executing a ticket, tell the founder its customer outcome, whether it
  is `mvp_required`, `mvp_supporting` or `beyond_mvp`, why, the smallest
  complete implementation, explicit exclusions, dependencies and test plan.
- Run `scripts/check-mvp-scope-gate-state.ps1
  -RequireExecutionAuthorized` before the first runtime/backend write or build.
- An MVP classification does not create implementation authority; all existing
  ticket, protected-boundary, provider, environment and founder gates still
  apply. `beyond_mvp` work is blocked unless the founder separately and
  explicitly authorizes that exact expansion.
- Prefer the smallest complete launch journey. Do not add speculative scale,
  optional depth, broad platform expansion or opportunistic polish to an MVP
  ticket.
- SQL Connect is founder-held until frontend UI/UX, API contracts, complete
  business logic, ownership, failure/recovery, privacy and retention produce
  one authoritative application-wide database map. No repeated provisioning,
  duplicate migration, partial-domain schema or exploratory live SQL Connect
  attempt is allowed.
- Before any SQL Connect provisioning or migration, additionally run
  `scripts/check-mvp-scope-gate-state.ps1` with respectively
  `-RequireSqlConnectProvisioningAuthorized` or
  `-RequireSqlConnectMigrationAuthorized`. Both fail closed until the complete
  database map and a fresh exact founder authorization are recorded.
- Before that completion gate, backend work is limited to already-complete
  shared global capabilities such as authentication/login and account erasure,
  or explicitly separate emulated/existing non-SQL-Connect backends.

## Founder-locked robust MVP delivery discipline

- The controlled public-go-live planning window is 60–75 calendar days from
  5 August 2026: 4–19 October 2026. This is a robust-MVP delivery control, not
  ticket activation or a waiver of provider, safety, privacy, accessibility,
  payment, regulatory, device or release gates.
- Before selecting or registering every successor ticket—including a
  preauthorized child—run the secondary robustness/reuse checkpoint in
  `docs/quality/MVP-PRE-TICKET-SELECTION-ROBUSTNESS-AND-REUSE-CHECKPOINT-20260805.md`
  and pin its assessment in `config/mvp-scope-gate-state.json`.
- Inventory and reuse existing native V2 and tested non-UI owners. Exact
  actor/outcome tickets remain separately traceable acceptance units, but
  ticket count never implies another screen, route, service, state owner or
  build.
- Do not create per-user-type duplicate screens, routes, code or backend
  owners. Use shared screens with exact authoritative data, capability,
  geography, terms and policy variants. A new screen, route or backend owner
  requires written necessity and duplicate-search evidence.
- Adjust execution topology through reuse, configuration, thin adapters,
  test-only acceptance and dependency ordering. Never use an adjustment to
  change an approved manifest/hash, weaken an approved outcome, add beyond-MVP
  scope or create authority.
- Apply `docs/delivery/MVP-ROBUST-60-75-DAY-DELIVERY-LOCK-20260805.md`,
  `config/mvp-robust-60-75-day-delivery-lock.json` and
  `scripts/check-mvp-delivery-discipline-lock.ps1`. Report a threat to the
  75-day target immediately with the smallest lawful mitigation; do not hide
  it by reducing robustness or truthful recovery.

## Founder-directed production ticket specificity

- `Business`, `provider`, `partner`, `merchant`, `professional`, `creator` or
  `Admin` is not a sufficient executable-ticket actor when the exact user type
  and permission are known.
- Every executable child ticket must name one exact user/workspace type, one
  exact capability, one authoritative outcome and its failure/recovery path.
- A parent may group journeys, but it cannot replace role-specific child
  tickets with a generic actor or silently grant several unrelated
  capabilities.
- Keep every approved profile type explicit in the registry. A deferred or
  beyond-MVP type remains registered disabled; registration does not authorize
  feature implementation or exposure.
- Apply the complete rule and current 29-profile MVP disposition in
  `docs/delivery/MVP-EXACT-USER-TYPE-TICKET-AND-JOURNEY-RULE-20260805.md` and
  `config/mvp-exact-user-type-scope-matrix.json` to all new ticket planning.

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

Before Social, creator commerce, external playback, channel connection,
publishing, analytics or payout work, also read completely:

1. `docs/decisions/ADR-0003-CREATOR-COMMERCE-ATTRIBUTION-AND-PAYOUT.md`
2. `docs/decisions/ADR-0004-CREATOR-CONTENT-DISTRIBUTION-AND-ANALYTICS.md`
3. `docs/delivery/SOCIAL-EXTERNAL-REACH-AND-CREATOR-STUDIO-FULL-STACK-CONTRACT.md`

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
- Never use HTML or a WebView as MoolSocial presentation. The sole approved
  MVP exception is a provider-owned YouTube embedded player loaded directly in
  an OS-provided Android `WebView` or Apple `WKWebView` under the full-stack
  Social contract. It may contain no MoolSocial page, navigation, form,
  business logic or copied provider interface.
- Never partially merge accepted screens into `main`.

## Approved-reference workflow

Founder-specific native Flutter amendment: for Universal/Mool shared
navigation, Eat, Ride, Book, Work and global Chat, apply
`docs/delivery/MVP-NATIVE-FLUTTER-WHIRLPOOL-NAVIGATION-MOTION-DIRECTIVE-20260805.md`.
The old prototype is inventory-only and is not visual/motion/navigation
authority for those surfaces. New work may proceed directly in isolated native
Flutter V2 after exact child selection and machine authorization, using a
versioned interaction/navigation contract, native responsive evidence, two
affected regressions and checksum-matched OPPO qualification. This amendment
does not change locked Screens 01–03, Social or accepted Buy boundaries.

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

The ten-step HTML-first sequence remains mandatory for every surface not
explicitly included in the founder-specific native Flutter amendment above.

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
- Every observed Codex mistake, false pass, false failure or escaped defect
  must be registered before another attempt in
  `config/codex-development-regression-registry.json`, with root cause,
  detection, prevention and retained evidence. Never rely on chat memory.
- Before each new implementation, build or device attempt, read
  `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md`, apply every matching
  active registry entry and run
  `scripts/check-codex-development-regression-memory.ps1` for the applicable
  phase. A retry is blocked until the preceding mistake is registered.
- Read each mandatory owner in an independent command/result. Read regression
  memory only in non-overlapping pages of at most 250 lines through verified
  EOF; never group it with AGENTS, handoff, policy, registry, ticket or source
  owners.
- A resolved mistake remains permanently registered. Future tests and gates
  may strengthen its prevention, but the entry and original failure evidence
  are never deleted or weakened.
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

## Mandatory APK regression machine gate

- Before any Android APK build, update
  `config/apk-regression-gate-state.json` for exactly one candidate and run
  `scripts/check-apk-regression-gate-state.ps1` with the exact candidate,
  version, mode, source fingerprint and complete runtime-define allowlist.
- A raw `flutter build apk` is not an authorized MoolSocial review build.
  Use `scripts/build-buy-device-review.ps1` for Buy candidates; it invokes the
  machine gate before Flutter and refuses stale, missing, failed or mismatched
  state.
- The machine state must list every required pre-build regression with existing
  evidence and every post-build/device gate as pending, passed or failed.
  Missing state fails closed. A narrative handoff cannot substitute for it.
- Each candidate receives a unique id, version, evidence directory and APK
  path. Rejected APKs, startup frames, logs and checksums remain immutable.
- A build consumes only its recorded one-build authorization. Update the
  machine state before another build; never reuse it silently for a successor.

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
