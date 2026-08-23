# Codex subagent mandatory coordination policy

Effective: 18 August 2026
Policy ID: `MOOLSOCIAL-CODEX-SUBAGENT-COORDINATION-001`

This policy is mandatory for the primary agent and every subagent before any
repository read beyond reconstruction, mutation, parser, test, build, browser,
device or external action. Chat context is not authority.

## Mandatory reconstruction

Every subagent must completely read both workspace and repository `AGENTS.md`,
the current bounded checkpoint in `docs/quality/ACTIVE-CODEX-HANDOFF.md`, this
policy, `config/codex-subagent-coordination-policy.json`, the applicable ticket,
the exact current regression tail and every assigned owner. It must then run:

Every mandatory owner is read in an independent command/result. Regression
memory is read only in non-overlapping pages of at most 250 lines through
verified EOF and is never grouped with another owner.

For the append-only active handoff, discover only the first two `^## ` heading
line numbers without emitting content. Read lines 1 through one-before-the-
second-heading only, in independent non-overlapping pages of at most 250 lines.
Never raw-read or fully emit the active handoff.

For `config/mvp-scope-gate-state.json`, parse without full emission and project
only exact file metadata/root property names plus the current state, ticket,
disclosure, authorization, execution, checkpoint and provider subtrees. Read a
named historical subtree only when applicable. Never raw-read the full owner.
For `preTicketSelectionCheckpoint`, emit only checkpoint ID/path/SHA/state,
current ticket ID and exact `selectedTicketAssessment`; never enumerate all
historical assessment properties.

1. exact branch and HEAD checks;
   full dirty-tree status output is prohibited; use a non-emitting porcelain
   digest plus literal claim-scoped status only;
   suppress helper return objects and emit only bytes/records/SHA/stderr-bytes/
   exit-code digest fields;
2. the applicable regression-memory gate alone;
3. `scripts/check-codex-subagent-coordination-policy.ps1` with its canonical
   task name, agent role, exact owner claims and current registry count/SHA.

No mutation or test may precede those passes.

## Primary-only coordination authority

Only the primary agent may:

- allocate a regression number or append/correct the regression registry;
- edit this policy, repository `AGENTS.md`, active handoff or active owner
  claims;
- change MVP selection/execution state unless a literal exclusive assignment
  from the founder and primary says otherwise;
- resolve overlapping owner claims or authorize a stopped agent to retry;
- serialize source seal, cycles, founder launcher, build, Play, OPPO, browser,
  account/private and other external actions.

A subagent that observes any mistake or unexpected result stops immediately,
reports the exact command/result/impact to the primary and waits for a literal
REG ID/path plus refreshed generation. It never chooses the next number.

## Exclusive owner protocol

- The primary records one canonical task and exact owner list per active
  subagent in the machine policy.
- A subagent may edit only those literal owners. A needed shared or unclaimed
  owner is a coordination request, not implied authority.
- Owner matching is case-insensitive after repository-relative canonicalization.
- The gate rejects duplicate owners, parent/child aliasing, `..`, absolute
  paths, primary-only owners and claims held by another active task.
- One owner is patched in one bounded operation, then parsed and read back
  before the next owner. Broad propagation patches across heterogeneous owners
  are forbidden.

## Codex and Cursor isolated production Git discipline

The immutable runtime starting point is accepted r60.87 commit
`f105195ba505dcc9f25a35ab64aab104dadb47c2` and annotated tag
`moolsocial-google-auth-r60.87-accepted-20260823`. The reusable work starting
point is the later annotated governance tag
`moolsocial-parallel-production-discipline-20260824-v37`. No feature lane may start
until that governance tag exists and descends from the accepted runtime commit.
Immediately before creating the tag, the primary runs `governance_preflight`.
That gate requires the production checkout to descend from accepted r60.87,
contain no post-baseline merge commit, pass the committed secret scan and have
zero staged, unstaged and untracked files. Every registered repository worktree
must also use an authorized path and be clean. Existing user evidence is
classified and preserved; it is not deleted to manufacture a clean baseline.

1. The production checkout stays on
   `remediation/prototype-conformance-2026-07-20` and is coordination-only while
   feature work is active. It is never switched, cleaned, reset, rebased or used
   as either agent's feature workspace.
   The retired legacy worktree path
   `C:\GUARANTEED OUTCOME\MOOLSOCIAL-WORKTREES\codex-cursor-baseline-reconciliation`
   is preserved outside the active worktree estate and cannot be used as an
   agent or integration starting point. A new authorized worktree is created
   only from the clean governance tag and only after the exact founder ticket
   and owner claim exist.
2. True parallel work uses separate primary-created Git worktrees directly
   under `C:\GUARANTEED OUTCOME`. Cursor uses `cursor_ui`; Codex uses
   `codex_auth`. Their exact file claims must be disjoint, and both branches
   begin at the governance tag.
   Each lane holds at most one open ticket. Cursor closes one UI/UX ticket
   before receiving another. Codex closes one founder-selected authentication
   provider before starting the next; the planned provider set is email link,
   Facebook, Instagram, YouTube Connect and X. Provider order remains a founder
   decision, and each provider is a separate ticket and remote closure.
3. Cursor may change only its ticketed native UI/UX and focused-test owners.
   Authentication, provider configuration, platform configuration, backend,
   dependencies, release controls, baselines, policy and locked Screens 01-03
   are forbidden in the Cursor lane.
4. Codex authentication work may change only its ticketed authentication,
   provider, platform bridge, focused-test and directly required auth-backend
   owners. Unrelated UI/UX is forbidden.
5. A later `codex_backend` lane for a Cursor-designed customer journey cannot
   start in parallel with unaccepted UI. It requires an exact founder-accepted
   Cursor UI commit, an immutable repository evidence owner and SHA-256-bound
   interaction/business contract. Its branch starts from that accepted UI
   commit and may not rewrite the UI presentation.
6. Each feature branch uses exact `work/<lane>/<work-id>` naming, contains no
   merge commit and changes no owner outside its recorded claim. Every commit
   is atomic and uses the gate-enforced `<lane-prefix>(<work-id>): <outcome>`
   subject. Rebase, squash, force-push and history rewriting are forbidden.
   From the governance baseline onward, each agent owns the cleanliness of its
   own worktree. Task start, handoff, founder acceptance, OPPO acceptance and
   ticket close require zero staged, unstaged and untracked files. Required
   non-secret source, tests and evidence are committed; secure local inputs are
   outside the repository or safely ignored. No user evidence is deleted to
   manufacture a clean status.
7. A completed implementation is not a closed Git ticket until its exact
   founder/OPPO-tested implementation commit is followed by one evidence-only
   closure commit. The closure commit has that implementation commit as its
   sole parent and changes exactly two owners: SHA-256-sealed founder
   requirement acceptance and successful OPPO evidence. The history and secret
   gates must pass, the worktree must be clean and `origin` must report the
   feature branch at exactly the closure HEAD. Each lane runs the
   `ticket_acceptance` phase before push and `ticket_close` after the exact
   remote readback. An agent with an open or dirty ticket may not accept a new
   ticket.
8. Consolidation uses a third primary-owned integration worktree and an exact
   `integration/moolsocial/<work-id>` branch starting from the governance tag.
   It admits only founder-approved feature commit SHAs through `--no-ff` merge
   commits. The integration first-parent history contains no direct source
   commit; a conflict requiring source authorship stops for a separate ticket.
9. The integration owner owns batch-wide Git closure. Before integration and
   candidate authority, every registered production, Cursor, Codex and
   integration worktree must be clean; every accepted feature branch must be
   remotely readable at its approved SHA; and the integration branch must be
   remotely readable at its exact clean HEAD. Dirty abandoned worktrees,
   untracked leftovers, stale remote refs and conflict-time source edits block
   consolidation. A clean feature worktree may be removed only after its exact
   commit has been integrated and remote closure has been verified.
10. Candidate authority stays closed until clean integration proves exact commit
   ancestry, merge provenance, owner closure, staged-secret safety, dependency
   integrity, focused tests, combined regressions and the applicable APK/AAB
   gates. Host, founder-screen and real-device/provider acceptance are separate
   evidence boundaries.
11. Promotion requires a new founder authorization, a curated remediation-branch
   update and a new annotated acceptance tag. `main` stays frozen and no feature
   branch merges directly into it or the remediation branch.

Ticket closure uses two sanitized JSON evidence owners. Founder evidence has
exact fields `schema`, `ticketId`, `workId`, `lane`, `acceptedCommit`,
`requirementsSatisfied`, `founderDecision`, `acceptedAtIst` and
`privateValuesEmitted`; its schema is
`moolsocial_ticket_founder_acceptance_v1`, decision is `accepted`, requirement
state is true and private emission is false. OPPO evidence has exact fields
`schema`, `ticketId`, `workId`, `lane`, `acceptedCommit`, `deviceClass`,
`ticketRequirementTested`, `result`, `testedAtIst` and
`privateValuesEmitted`; its schema is
`moolsocial_ticket_oppo_acceptance_v1`, device is `OPPO`, result is `passed`,
requirement-tested is true and private emission is false. Both IST timestamps
use an ISO-8601 `+05:30` offset. Both bind the tested implementation commit,
not the later evidence-only closure commit.

Every lane invokes `scripts/check-codex-subagent-coordination-policy.ps1` with
its exact `-ProductionLane`, `-ProductionPhase`, ticket and work ID. The machine
policy is the authoritative lane, root, branch, owner, dependency, commit and
integration contract; narrative approval cannot bypass it.

## Generation and test serialization

- Every task pins the registry count and SHA at preflight.
- Any registry movement invalidates unstarted mutation/testing and every state
  or readiness pin that binds the older generation.
- The primary freezes registry writers during final pin/self-test windows.
- A subagent never starts a test while another agent is changing one of that
  test's owners or bound hashes.
- Parser, behavior and dual-host runs use direct `-File` commands, one
  authoritative gate per shell call, with full session/exit metadata retained.

## Required prevention classes

Before action, every subagent checks the policy controls for:

- regression number collision, duplicate registry prefix and stale generation;
- overlapping/shared owner edits, stale patch context and cross-owner schema
  drift;
- guessed path/property/schema names and missing exact-path discovery;
- dense/raw/multirange output truncation and semantically incomplete output;
- unbounded full dirty-tree status output instead of scalar branch/HEAD,
  non-emitting status digest and literal claim-scoped status;
- yielded-session handle loss, orphan processes and power-outage recovery;
- file-versus-directory resolver misuse, reparse ancestors, sibling fixture
  aliases, fixture-root collision and incomplete cleanup;
- PowerShell quoting/interpolation/foreach-pipe/host coercion differences;
- false static oracles, validation-order masking and host-specific error classes;
- caller-authored evidence, replay, mutable proof/history and missing producer
  provenance;
- secret/private/account surface access and founder-only handoff boundaries;
- duplicate or out-of-order seal, cycle, build, upload, install, device,
  browser/provider and other external actions;
- branch/HEAD/workspace drift, destructive Git and user-file replacement.

## Outage and ambiguous-session recovery

After power loss, compaction, tool interruption or ambiguous yield, the task
performs no retry. It verifies branch/HEAD, memory and policy generation, asks
the primary whether any exact session was in flight, and probes only a known
process/session identity. It terminates only an identity-verified process and
registers any handle loss before retry.

## Immediate external-help escalation

When progress requires founder, account-owner, provider, device, permission or
other external help, Codex asks immediately with the smallest exact action,
the reason it is needed and the safe reply marker. It never silently leaves
the task on standby or `sideby`, and it never delays the request while doing
unrelated work. Asking for help does not broaden authority: private login,
credentials, secrets, provider approval and destructive actions remain
founder-owned, and every completed external checkpoint is followed by the
required generation and gate replay before continuation.

## Release-action single owner

Only the primary may activate an agent for a real source seal, cycle, founder
prompt, AAB, Internal Testing upload, OPPO update, browser/provider write,
authentication/account journey, SMS/email or other external action. The action
must have one exact ticket, actor, authority, candidate, attempt, preimage and
journal. Parallel release actions are prohibited.

## Completion

Before handoff, a subagent proves its owners, hashes, tests, fixture cleanup,
zero unauthorized actions and unchanged branch/HEAD. It stops, releases its
claim and performs no post-handoff command. The primary reviews every diff and
test before accepting the result.
