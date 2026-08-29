# Codex development regression memory

State: `FOUNDER_MANDATED_PERMANENT_ZERO_REPEAT_REGRESSION_RULE`

This is durable project memory for every Codex development attempt. Whenever a
mistake, escaped defect, stale assumption, false pass or false failure occurs,
Codex must stop the retry loop, preserve the evidence, add a unique entry to
`config/codex-development-regression-registry.json`, and add or identify a
machine-detectable prevention gate. The entry remains after resolution.

## Mandatory use

Before implementation, build and device work:

1. Read the registry and select every entry whose `appliesTo` includes the
   current phase or affected owner.
2. Run `scripts/check-codex-development-regression-memory.ps1` with the exact
   phase and build mode where applicable.
3. Run each entry's named detection/prevention gate.
4. Preserve new failure evidence; never overwrite the original evidence.
5. Do not retry until a new mistake has been registered with root cause and a
   concrete prevention.

The goal is cumulative prevention: a failure that occurred once becomes an
automatic constraint on all later attempts. A passing current test does not
permit deleting the historical regression.

## Current mandatory lessons

- Mool must remain an operable main-action launcher on root, chooser and
  downstream rails; dismissing it must preserve the exact current step.
- Chat return routes must retain exact Ride type, including Cab.
- Tests must follow the locked six-action MVP projection and must not restore
  removed standalone Pay assumptions.
- Android review builds must be invoked under PowerShell 7; Windows PowerShell
  5.1 can convert a benign Flutter stderr warning into a terminating error
  after Gradle has already produced an APK.
- Profile review builds must emit the exact candidate and ready-state runtime
  markers under device-review mode. `kDebugMode`-only provenance is invalid
  because `kDebugMode` is false in profile builds.
- A nonzero exit from an external process is not assumed to throw a catchable
  PowerShell exception. Every expected-pass and expected-rejection process
  check must capture and assert `$LASTEXITCODE` explicitly.
- PowerShell commands never use Unix backslash line continuation. Multi-file
  native commands use an explicit PowerShell array and argument splatting.
- A route-origin value used by sibling navigation branches is declared in the
  shared builder scope, never inside only one preceding conditional block.
- Evidence-text tests assert stable tokens or normalized text, not prose whose
  Markdown line wrapping can insert a newline.
- Expected-failure process output is normalized for ANSI control codes and
  whitespace before exact blocker messages are asserted.
- Expected-failure matching never relies on a dot wildcard crossing formatted
  PowerShell lines; normalized invariant tokens are matched after all
  whitespace is collapsed.
- Redirected PowerShell stderr objects are not assumed to stringify the same
  way in memory and on disk. PowerShell-script negative gates run in-process
  and assert the caught exception message; native-process gates use redirected
  text streams and `$LASTEXITCODE`.
- Mool is one stable Personal main-action hub. It must never alias Social,
  toggle an in-place main-action ribbon, open a modal/command menu or use Back
  to reveal such a menu.
- A dedicated route can still be a rejected launcher/menu. A durable Mool home
  cannot be a navigation-only question plus destination grid whose primary
  purpose is choosing another route; route mechanics alone do not establish a
  production home.
- An off-hub Mool transition preserves the current route and lifecycle owner;
  Back from the hub returns to that exact context. Social, Buy, Chat and shared
  account routes are not exceptions.
- A widget-harness pass is not sufficient navigation evidence. The production
  router path and a real installed-APK tap must exercise the same callback
  before device acceptance.
- Device qualification stops at the first founder-visible screen mismatch;
  later matrix cases remain unaccepted until a successor fixes that frame.
- Removing a rejected navigation owner requires a full search and the complete
  universal vertical/accessibility suite. Older tests must assert the current
  one-tap hub contract and may never preserve a deleted modal interaction.
- A patch hunk is scoped to exactly one re-inspected target file. Context from
  a second file is never combined under the first file's update header.
- Flutter and Dart app commands run from `apps/mobile`, whose `pubspec.yaml`
  defines the package. Repository-level gates use an explicit repository root.
- Complete journey tests may not mix a known later-child defect with the child
  under test. Stable-hub return is proved through each exact production owner;
  Social main-action-palette removal remains an explicit Social child.
- A production navigation test first proves that its initial route resolves to
  the intended owner. Legacy-contained routes cannot stand in for live owner
  routes when testing dock wiring.
- Deleting a navigation owner includes removing its now-unused imports, and
  affected-file static analysis is mandatory before the child can complete.
- Scope-state JSON transitions use small verified hunks. Exact stored values
  are queried immediately before patching; large rendered-output replacements
  are not used as edit context.
- Test filenames are discovered with `rg --files` or directory enumeration.
  A guessed successor name is never supplied as a required command path.
- Every `rg` invocation declares whether zero matches is valid. Discovery and
  absence searches translate exit 1 to an explicit zero-match result; only
  required-match inventories reject it. Values above 1 are command errors.
- Optional `rg` searches are isolated from successful required reads so an
  undeclared zero match cannot change the status of a compound inspection.
- Tests comparing `SemanticsData.flagsCollection` values import
  `dart:ui show Tristate`; semantic usage does not imply a Flutter semantics
  library import.
- Accessibility assertions read the keyed control's `SemanticsData`; they do
  not assume whether framework semantics nodes are merged or standalone.
- Social list-card taps reserve the fixed bottom rail's occlusion zone after
  scrolling. `ensureVisible` alone is not sufficient hit-test evidence.
- Merged keyed semantics labels are asserted by invariant tokens, not exact
  newline serialization including visible child text.
- Social inline-depth Back followed by Mool/Back is a mandatory chained
  production-router case; intermediate visible owners and Navigator stack
  state plus the final selected sub-action must be proved before device
  acceptance.
- An imperative GoRouter `push` is not diagnosed from
  `routeInformationProvider` URI unless URL reflection is explicitly enabled.
  Production navigation tests assert visible owners and `Navigator.canPop`
  stack state for push/Back transitions.
- When system Back fails but the same screen's header Back succeeds, isolate
  stale source `PopScope` registration before modifying the destination's
  already-working `onBack` callback.
- Post-edit formatting first runs in normal mutating mode. The
  `--output=none --set-exit-if-changed` form is reserved for a subsequent
  no-format-diff verification.
- A stable hub with custom origin fallback owns system Back explicitly through
  `PopScope(canPop: false)` and routes it through the same callback as header
  Back. A prior screen is not changed when only the destination's Back source
  ownership differs.
- PowerShell stream redirection never trails a completed compound statement.
  Evidence wrappers redirect an invoked script block or place `Tee-Object`
  inside the validated block.
- Statement-form PowerShell loop output is assigned or wrapped in `$()` before
  piping; a bare `foreach { ... } | ...` is never used in required inventory.
- Array-valued PowerShell parameters are splatted in-process or constructed
  inside the invoked script. A parent-shell array is never passed directly
  through a native `pwsh -File` boundary.
- PowerShell XML token checks use unescaped double quotes inside single-quoted
  literals; helper summaries are reconciled with retained raw XML before they
  become device-acceptance evidence.
- Windows path inventories use literal `StartsWith`/`Contains` comparisons,
  or normalize to forward slashes before regex. Raw backslash paths are never
  inserted into PowerShell `-match` patterns.
- Command stdout may be captured as a log, but authored or appended evidence
  text is a file edit and uses `apply_patch`; shell append/write helpers are
  prohibited for artifacts as well as source.
- Required multi-file excerpt inventories never depend on PowerShell nested-array
  unrolling. Use explicit per-file reads, or strongly typed range objects and
  integer bounds, so a one-range file cannot silently change the wrapper shape.
- Screenbook/reference discovery enumerates filenames first and then reads only
  exact relevant files; broad searches that produce truncated output are never
  accepted as complete design evidence.
- Buy navigation preservation tests establish state after `BuyV2Screen` mounts
  through the real rail, or pass the matching initial destination. A conflicting
  pre-mount session mutation is not valid restoration setup.
- Journeys migrated from a deleted main-action palette assert the stable Personal
  hub first and then use `mool-action-*`; old Social/Buy palette keys are
  forbidden in the affected test boundary.
- Application dependency-graph work captures the approved-UI-lock result both
  before and after implementation. A clean-at-HEAD pre-existing lock mismatch
  is preserved as a separate release blocker and is never repaired by mutating
  the accepted screen; affected-path diff evidence must still prove no child
  change reached the protected file.
- Independent final gates are reported independently. One failing gate must not
  hide the completed outputs of other gates through fail-fast promise handling.
- A planned `Tee-Object` path is not evidence until `Test-Path` confirms it
  exists. Missing failed-command output is reconstructed with `apply_patch`
  before any registry entry references that path.
- Navigation source tests preserve stable control keys and forbid only the
  rejected callback inside the exact action block. Removing an alias does not
  imply removing the interaction identity.
- Windows repository searches never embed wildcard components in required path
  arguments. Every `rg` path token is a literal existing file or directory;
  wildcards appear only after `-g` or in a second pattern over `rg --files`
  output. A compound discovery is failed if any component exits nonzero.
- Repository-owned registry and machine-state paths are read from `AGENTS.md`,
  the owning checker or exact filename discovery. A guessed config filename is
  never used for a required acceptance check.
- Every founder-visible navigation directive is normalized into a versioned
  instruction-to-assertion scenario before implementation: entry state, user
  action, exact visible destination, Back result, forward/return result,
  preserved state and forbidden alternatives. Each row requires a static
  contract, a production-router visible-owner test, a named OPPO evidence step
  and an explicit machine-state result. Route existence, tap dispatch and
  `Navigator.canPop` do not by themselves prove the requested product outcome.
- Repetition of a founder instruction is a process-regression signal. Existing
  tests must be audited against the literal requested outcome before more code
  or another APK is accepted; an equivalent implementation under a different
  widget or route shape remains the same regression.
- Parsed JSON summaries verify the required root property exists before array
  coercion, counting or membership checks. PowerShell null-to-array behavior is
  never accepted as evidence; the owning schema/checker remains authoritative.
- Expected PowerShell failures are accepted only from an in-process caught
  `Exception.Message` or another structured field. Formatted host/error-stream
  rendering may be retained as evidence but is never searched for acceptance
  tokens, even after whitespace or ANSI normalization.
- Route-token inventories use isolated literal `rg` calls with declared result
  semantics. Required searches need exit zero and at least one match; optional
  absence names exit one as zero results and rejects only codes above one.
- From `apps/mobile`, Flutter and Dart commands use only `lib/...` and
  `test/...` paths; repository-relative `apps/mobile/...` paths run only from
  the repository root. Compound validation checks each component exit
  immediately so a later pass cannot mask an earlier failure.
- Required production-owner, route and implementation-token searches target
  `lib` only. Test discovery is separate; an assertion's self-match can never
  prove that the corresponding production key or behavior exists.
- Widget keys are copied from their exact production owner or an already-proven
  repository contract, never inferred from displayed labels. Missing required
  keys are reported by an isolated source-only search before a replacement
  assertion is written.
- Test-suite directories are taken only from an immediately verified filesystem
  or `rg --files` inventory. Product categories do not imply directory names;
  when no category directory exists, use exact discovered test filenames.
- Protected runtime cycles reuse exact previously qualified test owners and
  exclude any source containing `matchesGoldenFile` unless the current ticket
  explicitly authorizes golden verification. A failed golden run is preserved;
  accepted references and protected baselines are never updated as a shortcut.
- Prior evidence and runner filenames are selected from an exact literal
  directory or `rg --files` inventory before a separate required read. A
  remembered numeric prefix is never used to guess an artifact filename.
- New OPPO helpers are source-inspected before first execution. UIAutomator
  attribute needles use exact raw XML tokens with unescaped double quotes
  inside PowerShell single-quoted literals.
- Device-helper native exit status is owned by the branch that executes the
  native command. Pure capture branches use an explicit zero action result and
  never inherit a null or stale `$LASTEXITCODE`.
- After composer focus or text entry, OPPO qualification confirms the active
  IME visually or from system window/input state. Back closes the IME first;
  hidden app semantics never prove that an overlaid control is tappable.
- After a Chat composer draft exists, OPPO navigation runs one action, one
  screenshot/hierarchy and one IME decision at a time. Actions are never
  batched across a draft-thread return, and a visible-owner mismatch rejects
  the named capture as route evidence.
- Global OPPO setting tests require a read-only permission/capability preflight
  or explicit founder-performed setup. Cleanup is guarded by a confirmed
  mutation-success flag; a security rejection is never bypassed or retried.
- Social rail acceptance includes pairwise production-owner transitions from
  every selected subaction to every other subaction. Create → Shorts is a
  mandatory OPPO row, and the settled visible owner plus selected semantic—not
  clickable bounds or dispatch alone—determines pass/fail.
- The IME rule applies to every composer-capable owner, including Social
  Create. Device rejection requires visual proof that the target is physically
  exposed; stale accessibility bounds behind the keyboard are never hit-test
  or product-defect evidence.
- Large JSON queues and machine-state documents are never serialized wholesale
  for planning or acceptance. Discover root properties first, then read named
  scalar summaries and bounded child projections with explicit counts. A
  truncated render is rejected and cannot establish queue state.
- A PowerShell script or function invocation is validated through its immediate
  PowerShell success state or an explicit returned result. `$LASTEXITCODE` is
  read only immediately after the native executable that owns it; stale native
  status can never overturn a checker that visibly completed successfully.
- Large append-only handoff documents are never printed as a single unbounded
  tool result. Discover headings first and read exact current sections in
  bounded ranges; when a complete read is required, page through verified,
  non-overlapping ranges and confirm total line coverage.
- Multi-root repository searches use only literal paths returned by an
  immediately preceding top-level inventory. A missing-root exit code
  invalidates the compound discovery; partial matches are leads only until a
  separate required search passes against verified roots.
- Add File patches are inspected before execution so every content line,
  including wrapped prose, begins with an addition marker. An atomically
  rejected patch is registered and unchanged target state is confirmed before
  retry.
- Negative tests that intentionally violate readonly or branded compile-time
  contracts cross an explicit `unknown` boundary into the smallest structural
  mutation interface. Focused strict typecheck must pass before compiled test
  execution.
- Focused compiled tests write into a new exact ticket-evidence directory and
  retain their outputs. Test wrappers contain no recursive cleanup; disposable
  compilation cannot justify an unnecessary destructive action.
- Gate parameter values are copied from the checker's declared validation set
  or an immediately preceding passing invocation. Activity names are never
  guessed as machine-gate phases.
- Complete test suites capture each cycle's full reporter output in a separate
  retained ticket log, record the native exit code immediately and emit only a
  bounded final summary. A truncated rendering cannot be the sole acceptance
  evidence.
- Acceptance hashes, versions, codes and device identities are emitted as
  explicit scalar `key=value` lines. Native output is captured into strings
  with its exit code recorded immediately before filtering; tables and direct
  native-to-cmdlet streaming cannot establish exact identity.
- Tests for missing exact-optional fields use explicit omit controls and
  conditional object spreads so the property is structurally absent. Test
  helpers never pass explicit `undefined` to an exact optional property.
- Negative-test helpers apply defaults first and caller overrides last. Object
  construction order must preserve the exact invalid field the test intends to
  send to production code; defaults may never shadow it.
- Reuse assessment separates production-source owner discovery from complete
  docs/config authority discovery. Each search has verified literal roots and
  a separately labelled count; neither result can satisfy the other's proof.
- Durable state transitions are split into small independent patches: create
  evidence, update one state owner, parse it, and verify exact values before
  touching the next owner. Truncated or missing tool output never proves that a
  mutation succeeded.
- At every resumed context boundary, read each checker parameter declaration
  and copy its exact names and allowed values before invocation. Remembered
  interfaces and prior summaries are not accepted as gate evidence.
- Persisted and cross-boundary JSON digests use a recursively key-sorted
  canonical projection. Direct object serialization is not an integrity
  contract; round-trip normalization must reproduce the same digest.
- Before ticket acceptance, every explicit human-journey choice and named
  failure state maps to a test assertion. Exact ticket wording outranks a
  condensed assessment; a green test is superseded if it encodes the wrong
  product rule.
- Complete reads of multiple substantive documents are paged separately with
  verified, non-overlapping ranges and explicit coverage through each final
  line. Manageable per-file sizes do not prove their combined output is safe.
- Multi-root search arguments are mechanically derived from preflight objects
  filtered to `exists == true`. An absent path printed by a preflight is never
  retained in a separately hard-coded search list.
- Large dirty inventories enable invocation-local Git long-path support,
  capture stdout and stderr separately, and render only scalar count, digest
  and warning count. Status bodies and warning streams are never printed.
- Every public command and query normalizes every runtime field after
  authorization and before business-data selection. Compile-time request
  types are not adapter-boundary evidence; negative fixtures cross `unknown`.
- Every nested persisted discriminated union has an exact runtime schema
  normalizer after deserialization. Audit source hashes are explicitly rebound
  to the normalized selected provenance; shallow freezing is not validation.
- Union-returning functions are evaluated once per assertion path. Variant
  fields are read only from the same captured value after discriminator
  narrowing; repeated calls cannot share a TypeScript or semantic narrowing.
- Restart normalization revalidates every original temporal business
  invariant, not only timestamp format and linked evidence equality.
  Coordinated-tamper tests change all cross-linked timestamps together.
- A composite source becomes effective only at the maximum effective time of
  every required component. Leaf-source time never substitutes for base and
  dependency readiness; tests place the base later than the leaf.
- Any new source or test expected to exceed about 300 lines is created as a
  small scaffold plus bounded section patches. Verify line count or tail after
  every section and strict-typecheck the completed file. A truncated patch
  result is unknown until read-only reconciliation and never proves success.
- Add File patches remain file-local and are mechanically inspected so every
  content line, including blank and wrapped prose lines, carries its addition
  marker. After any rejection, verify unchanged targets before retrying.
- Durable evidence-producing commands use absolute canonical production
  repository paths. If a relative path is unavoidable, resolve and validate it
  before execution; parent traversal is never accepted by mental path counting.
- Before every regression-checker call, print its ValidateSet and the selected
  copied value. Ticket test work uses `-Phase implementation`; `tests` is an
  activity label and is never a valid checker phase.
- Exact source-code phrase searches use fixed-string mode with shell-literal
  quoting. A nonzero search is checked for syntax and path errors and never
  treated as evidence of absence on exit code alone.
- Idempotent replays validate every tenant, actor, workspace and participant
  binding supplied outside the command envelope before returning. Only
  explicitly time-varying eligibility may remain new-command-only.
- Persisted aggregate roots and every nested record use exact plain-object key
  schemas before value validation. Typed object spread is not restart
  normalization and must not retain undeclared or personal fields.
- Qualification commands use absolute canonical production-repository paths
  for every gate, source, output and reporter operand. The ban on mental parent
  traversal applies to inputs and scripts as well as durable outputs.
- A direct package compiler runs with the exact package root as its working
  directory, or declares package type roots explicitly. Absolute source paths
  do not replace module and ambient-type resolution context.
- Every prose Add File is read back at its opening and closing sections and
  inspected for patch-marker contamination or joined words. Patch syntax is
  never escaped into intended document content.
- Every operand in a combined qualification command, including diagnostic
  reads and scalar preflights, uses an absolute canonical path. A PowerShell
  read error invalidates its scalars even if a later native command succeeds.
- Before composing existing receipt contracts, inspect every owner's exact
  result-digest rule. Cross-owner validation asserts only common evidence and
  digest format unless each owner exports a verifier; owner semantics stay local.
- A governance lineage binds the smallest independently effective source
  subject: exact global family or exact schedule override ID, not only its
  containing source set. Proposals and restart references enforce that scope.
- Registry append context is copied verbatim from an immediate tail read. Parse
  the registry and verify the exact final ID after every append.
- Closed machine enums are copied from the checker's declared allowed set.
  Dependency holds use dedicated state, missing-dependency and authorization
  fields; human hold language never becomes an invented enum.
- Read every checker parameter block before its first invocation. The delivery
  lock uses `-RequireTicketSelectionAssessment`; ticket identity belongs only
  to the scope gate's declared `-CandidateId`.
- A dependency-held successor is recorded in dedicated ticket and portfolio
  hold state, outside the one active execution slot. The MVP scope gate stays
  closed with no ticket ID until every dependency clears.
- Diagnostic output is captured in memory or a canonical repository artifact
  path. Environment temp directories and every other out-of-workspace
  intermediate are prohibited by the exact workspace boundary.
- Public cross-owner source composition normalizes set version, target revision
  position and schema, audit schema, common receipt scope and discriminators.
  Typed source interfaces never substitute for deserialized runtime checks.
- External-provider email state is reconciled from the live thread, current
  draft inventory and repository state before any reply, distribution or
  readiness decision. A sent message or later provider reply supersedes an
  older `prepared_unsent` machine scalar and is recorded durably first.
- Before an authorized Firebase Hosting release, prove the saved CLI session
  can resolve the exact project and hosting target with a non-mutating
  authenticated preflight. Expired authentication stops before deploy; never
  bypass it or source alternate credentials.
- Inline PowerShell composed through another language avoids nested
  escape-sensitive newline literals. Prefer byte-level comparison,
  environment newline normalization or a repository script; inspect the exact
  rendered command before any unavoidable composed execution.
- Retired public identities and forbidden customer copy are audited with a
  case-insensitive normalized expression covering optional punctuation and
  whitespace variants. Live verification also extracts surviving footer and
  structured legal-name values per route; one fixed literal cannot prove
  semantic absence.
- Interactive CLI authentication never runs in the non-interactive task
  runner. After explicit founder approval, use a visible founder-controlled
  terminal for the exact reauthentication command, then verify the intended
  project with a separate non-mutating CLI preflight.
- Ripgrep receives existing literal file or directory roots. Filename
  selection uses `rg -g` filters; never pass a Windows path containing `*` as
  though PowerShell will expand it for a native evidence command.
- Every significant canonical public-page change updates that URL's truthful
  sitemap `lastmod` in the same ticket. Tests bind the exact modified-date set,
  deployment verifies the live sitemap, and authorized Search Console evidence
  distinguishes Google's indexed copy from the current live page. Live HTML
  correctness alone cannot prove that a public search snippet has refreshed.
- Closed machine enums are copied from the enforcing checker's exact allowed
  set before state is written. External-service activity belongs in scope,
  dependency and evidence fields; it never invents a new implementation
  disposition.
- Public identity disassociation acceptance covers both brand-query directions,
  AI-generated result surfaces and a domain-restricted retired-identity query.
  Every affected owner-controlled canonical URL is enumerated, its stale snippet
  is cleared without hiding the valid page, and its reindex request is recorded.
  One founder screenshot or one inspected URL is never global search evidence.
- Readiness evidence searches start with known configuration, quality-document
  and exact candidate owners. Very large retained artifact trees are searched
  only through a filename inventory and narrow `-g` filters; routine lookup
  never starts with an unbounded recursive repository-root content search.
- Shell commands never create or modify repository text files through
  `Set-Content`, `Out-File` or output redirection. Text evidence is applied with
  `apply_patch`; owning tools such as `adb pull` may still create their native
  binary or XML capture outputs in the exact retained evidence directory.
- A bottom-navigation Home is not a return sheet. Its untouched OPPO frame has
  no header Back control, dominant Continue-origin action or origin-specific
  return copy; selected Home retap has no route, state, haptic or history side
  effect. Route retention alone cannot qualify first-class visible ownership.
- Primary-navigation overflow is qualified from the untouched compact frame.
  It needs a persistent finite position/overflow cue, a meaningful next-action
  peek and semantic scroll context; scripted `ensureVisible` or a deliberate
  audit swipe proves reachability but never proves real-user discoverability.
- Ripgrep literal-root validation covers every operand, including secondary
  documentation roots. Windows wildcard path operands are always replaced by
  an existing literal root plus `-g`; one invalid operand invalidates the whole
  command and its output is never accepted as absence evidence.
- Optional ripgrep means its zero-result exit is expected and must be handled
  explicitly. Bare `rg` is used only where at least one match is a required
  invariant; all discovery probes use the exit 0 / exit 1 / exit greater than 1
  wrapper before their output can influence a decision.
- Dirty-state sealing never starts with repository-wide untracked traversal in
  an evidence-heavy workspace. Use tracked status without untracked discovery,
  then enumerate untracked files only in exact candidate-input roots; retained
  historical artifacts are not routine build-fingerprint inputs.
- Repository-global gates in a shared dirty workspace require a new-owner
  reconciliation first. A separately ticketed protected file outside the
  candidate aggregate remains an explicit expected rejection; it is never
  silently allowlisted or relabeled as an applicable mobile-gate pass.
- A selected navigation root with no reselection behavior is explicitly
  disabled at the component boundary. It never uses an empty callback to mimic
  a no-op; its semantics expose current/selected and disabled state, with no
  route, state, haptic, focus or history side effect.
- Pre-build evidence updates use small bounded patches with verified file and
  hunk boundaries. Read every result back before hashing; source identity is
  recomputed only after all regression registrations and evidence edits settle.
- Authored runtime source seals exclude ignored machine-generated metadata such
  as Android `local.properties`. Expected build-tool rewrites are asserted
  separately; before/after drift compares the stable authored aggregate and
  records any generated transition without initiating a second build.
- Bounded device evidence preserves line ownership. Never pass a multiline
  `Out-String` scalar to `Select-String`; split lines first or extract anchored
  scalar values so one match cannot emit an entire package or activity dump.
- Native exit status is checked immediately after the native command. Capture
  its output array first; only after validating `$LASTEXITCODE` may PowerShell
  filtering or scalar normalization run, because pipeline stages can unset or
  obscure the native exit value.
- Customer-visible and accessibility copy expresses a customer goal, action,
  benefit or plain-language reassurance. Internal component and engineering
  rationale—including rail, route, owner, state, stay fixed, or without
  inventing—never substitutes for product wording; OPPO copy review precedes
  qualification.
- Small patches copy their exact immediate current context before application.
  Similar widgets or adjacent remembered source never supply assumed hunk
  lines, even for a one-line copy or semantics change.
- Repository PowerShell checkers succeed by returning without a terminating
  error. `$LASTEXITCODE` validates only a native executable immediately after
  that executable; it is never used after a PowerShell script invocation.
- Navigation gates prove behavior and production copy as separate invariants.
  Customer-facing semantics never need to preserve internal component wording;
  scroll direction, tap targets, persistent overflow cues and initial-frame
  activation remain independently required when wording changes.
- Manually assembled test commands use literal paths resolved from the current
  repository file inventory. A missing test path invalidates the complete run;
  passing output from sibling tests in that process is not retained as suite
  evidence, and the corrected command restarts the whole intended set.
- One screen position has one navigation meaning across the product. Global
  Mool, main-action and Chat controls keep stable geometry and selection on
  every main root; destination subactions remain inside destination content.
  A destination-owned rail or top-level header Back cannot substitute for the
  global shell, and fresh authenticated no-deep-link launch starts at Social.
- The top destination zone is reserved for advertising, promotional video and
  primary content, never routine sub-actions. Destination-local sub-actions
  stay visually coherent in the lower one-handed thumb-reachable content zone
  with one direct tap, while the founder-approved global bottom rail keeps its
  stable geometry. A More menu, modal, palette or multi-tap drill-down cannot
  hide primary sub-actions, and OPPO qualification must prove the untouched
  first frame plus real one-handed journeys before acceptance.
- Static navigation gates validate composition ownership, not an obsolete
  direct-widget spelling. A destination may supply its local controls through
  the shared contextual shelf only when that shared owner demonstrably ends in
  the unchanged global rail; both the composition gate and behavioral journey
  tests remain required.
- Buy's primary destination shelf contains Shop, Wholesale, Medicine and
  Orders. Help remains contextual to order recovery or Assist and must not
  reappear as a fifth primary tab; static gates and behavioral journeys enforce
  both that inventory and the shared shelf-to-global-rail composition.
- Motion-containment gates follow the full navigation composition chain.
  Destination owners provide their existing local rail to the shared lower
  shelf, and the shared owner terminates in the global rail; direct per-screen
  global-rail calls are not required, while page motion, reduced motion and
  first-level top-Back prohibitions remain independently enforced.
- Mixed owner inventories are never rewritten as if every member has the same
  ticket scope. C11 shelf ownership applies exactly to Social, Buy, Eat, Ride,
  Book and Work; a separately owned Shared screen keeps its direct global rail
  unless a later authorized ticket explicitly changes it.
- Brand gates trace canonical icon ownership through shared navigation
  composition. A destination wrapper is valid only when the destination uses
  it, the wrapper terminates in the global rail, and that rail still renders
  the canonical Mool launcher; direct per-screen spelling is not the brand
  invariant.
- A structural change to a feature root expands the affected boundary to that
  feature's complete test directory, even when dedicated and inherited cross-
  feature navigation batches pass. Failures are diagnosed with exact bounded
  names and errors, corrected by behavior, and followed by two identical full
  feature passes before APK sealing.
- Repository PowerShell gates and native Flutter diagnostics run as separate
  commands in their owning working directories. Never inspect
  `$LASTEXITCODE` after an in-process PowerShell gate; capture it immediately
  after Flutter and only then parse the captured diagnostic output.
- Ripgrep never receives a Windows wildcard as a path operand. Use a verified
  literal directory with `--glob`, and keep independent diagnostic reads in
  separate failure boundaries when one result is still useful if another
  probe fails.
- Multi-failure corrections are not presumed complete from a reduced failure
  count. Re-run the exact affected files, extract every remaining failure with
  a bounded reporter, register second-order causes, and only then retry the
  smallest rightful owners.
- Formatter and analyzer commands have separate working-directory ownership
  and exit evidence. Every operand is resolved for that exact directory;
  analysis cannot hide an earlier formatter rejection in the same shell.
- Tests locate known offscreen elements by exact ownership and
  `ensureVisible`; they do not guess fixed drag distances that can overshoot
  when navigation chrome or viewport height changes.
- After scrolling between distant content panels, tests distinguish visible
  reachability from retained ownership. They prove the first action while it
  is visible, then use offstage-inclusive finders only to prove it remains
  owned after the lower target is visible.
- Accessibility geometry duplicated across runtime and governance changes
  atomically. An overflow-safe runtime constant, its exact brand contract and
  static checker must agree, while the compact 140-percent behavioral journey
  independently proves the change.
- A founder-authorized ticket manifest is immutable after its checksum is
  approved. Host, build, device and review status belong in separate state
  contracts and evidence; never repair a manifest-checksum rejection by
  changing the approved hash to match a status mutation.
- `adb devices` is captured and its native exit checked before parsing. Device
  presence requires exactly one anchored matching data row selected with an
  explicit filter; array `-notmatch` never decides connectivity because header
  and blank lines are expected nonmatches.
- Lower reachability is not sufficient device UX acceptance. The shared
  destination sub-action surface is translucent and no taller than 48 logical
  pixels, each action remains at least 44-by-44, destination family ownership
  stays explicit, and OPPO screenshots must prove that Buy grids and every
  other primary content surface remain visually dominant before acceptance.
- Dart imports are never assumed to be transitive. A new shared-navigation
  symbol must come from a direct import or an already public token visible to
  that file, and full analysis proves the import boundary.
- Repository PowerShell gates run alone from the repository root; Flutter and
  Dart commands run alone from `apps/mobile`. A combined command never mixes
  their working-directory or exit-code ownership.
- A 48px navigation envelope does not prove a 44px child target. Shared and
  destination-specific keyed tap owners are measured after final layout; one-
  pixel vertical insets preserve rounding allowance without increasing the
  rail or weakening the 44px accessibility minimum.
- Dirty-source seals enumerate only explicit production source/config/test/
  doc/script scopes. Repository-wide untracked scans are forbidden because
  retained artifacts and browser profiles are evidence, not build source, and
  can contain deep Windows paths.
- Source-aggregate operands come from the live `rg --files` inventory or an
  exact already-read path, never a remembered concept name. The aggregate
  helper throws on any missing file, and output accompanied by a PowerShell
  error is always discarded even if the shell later reports zero.
- Destination family-rail qualification begins at each global main-action tap,
  not only at a deep route. The first production-router frame must show the
  correct family rail and selected default action in one tap; retired chooser
  roots are redirected before rendering, rejected statically, and replayed on
  OPPO for Social, Buy, Eat, Ride, Book and Work.
- A registry entry references only gates and evidence that already exist at
  parse time. Planned successor tests join the gate list only after their
  exact paths are created and verified; future filenames never serve as
  current machine evidence.
- A Dart lookup derived by indexing another const collection is top-level
  `final`, not assumed to be a valid const expression. Focused analysis runs
  before widget execution or candidate sealing.
- When production retires an intermediate chooser, inherited router tests are
  migrated atomically: the retired root must show its default family owner on
  the first frame, and non-default choices are exercised through the local
  rail. Legacy component harnesses never qualify the production route.
- Ride Bike, Auto and Cab share one booking owner and switch selected type in
  place. Tests never invent duplicate-route Back history; exact state is
  proved on the selected rail and across separate Chat and Mool round trips.
- A verbose connected Flutter batch is not a diagnostic boundary when startup
  logs can truncate failures. Inventory-proven files run independently until
  exact owners pass; full-cycle evidence then uses the bounded reporter.
- Mool-origin and global-origin action matrices share the same direct default
  owner contract. Eat Home, Ride Booking, Book Doctor and Work Earn replace
  retired chooser expectations while Back must still restore Mool exactly.
- Moving a global action from a dynamic root to an exact default route also
  moves shared transition-page ownership. Normal mode retains the finite main
  destination motion; reduced motion renders the real owner directly.
- During a pushed route transition, settled outgoing and active incoming pages
  may share the motion key. Tests select the one animation strictly between
  its start and end values and validate its paired slide.
- A numerical rail-height pass is not visual acceptance. Destination
  sub-actions use one maximum-44px transparent unboxed strip: 44px targets,
  tint plus a two-pixel selected line, no family tile or filled action cards,
  and OPPO first frames that keep content dominant.
- Design tokens are copied from their exact declaring owner. An abbreviation
  in the spacing family is never assumed to exist in the radius, color,
  metric or motion family.
- A 44px strip with a decorated border may expose only a 43px child. Family
  connectors paint in a positioned overlay and never consume layout; all six
  keyed action targets are measured directly after final composition.
- Historical artifact lookup starts with one exact evidence directory or a
  bounded filename inventory. Current affected tests come from live source
  owners; repository-wide retained-artifact content searches are discarded.
- A ripgrep pattern beginning with `-` always follows the explicit `--`
  end-of-options separator. An option-parse failure never proves absence.
- Ripgrep ordering is all options and globs, then `--`, then the pattern and
  verified literal roots. The separator never precedes remaining options.
- Bounded Flutter JSON summaries join every failed `testDone.testID` to its
  `testStart` name and URL. Numeric IDs alone never identify an owner or
  authorize a test change.
- Vertical exposure suites use the direct-root contract: first frame is the
  default family owner, non-default local Back returns to default, top-level
  roots create no chooser history, and explicit Mool returns exact context.
- Ride remains the explicit in-place exception to generic local-route Back
  rules: Bike, Auto and Cab share one booking owner, and each selected type
  must survive an explicit Mool visit and Back without invented history.
- A bounded JSON test-ID map is not qualified until one `testStart` label is
  visibly non-empty. PowerShell metadata uses `$($event.test.url)` and
  `$($event.test.name)`; blank joined labels authorize no mutation.
- Retiring a destination chooser requires an all-consumer inventory: root and
  Chat config, hub/compatibility/Back tests, and legacy recovery buttons must
  name exact supported owners, not compatibility roots or chooser widgets.
- A retired-root inventory crosses test-directory boundaries. Buy and other
  destination suites that exercise Eat, Ride, Book or Work must assert the
  same direct default-owner contract as universal navigation suites.
- Static route gates validate behavior owners, not obsolete declaration
  adjacency. A dynamic pre-render redirect and its retained pageBuilder are
  proved separately, alongside every exact default route motion owner.
- Windows ripgrep path operands are exact literals. Wildcard discovery uses
  `rg --files` plus a bounded filename filter; any path-error group is
  discarded completely even when its other reads may have succeeded.
- A transparent 44px sub-action row is not automatically a connected family.
  The shared destination wrapper has no side-to-side surface and uses one
  noninteractive, semantics-excluded finite gradient wave whose endpoints bind
  the selected global main action to the exact selected local action. It moves
  left or right with selection, settles immediately under reduced motion and
  never changes the 44px tap owners or approved global rail.
- JSON state patching parses values for meaning and separately copies the exact
  bounded source context, including string-versus-number representation. An
  atomically rejected combined patch is confirmed unchanged and is never
  treated as partial success before a smaller retry.
- Noninteractive-overlay tests select ancestor owners by behavior. They require
  exactly one `IgnorePointer` with `ignoring == true`; unrelated framework
  ancestors with `ignoring == false` cannot create a false duplicate-owner
  rejection, and semantics exclusion is proved by an excluding ancestor.
- Route-mounted local-selection motion starts as soon as dependencies resolve
  the accessibility policy. It never waits for an extra post-frame callback;
  in-place and cross-route selections both prove an intermediate finite frame,
  while reduced motion settles directly at the new endpoint.
- A transparent fixed-navigation layer separates visual continuation from hit
  safety. The destination canvas may extend behind the wave, but body SafeAreas
  retain bottom protection so buttons, grids and final scroll content never sit
  under the local-plus-global navigation stack. Complete vertical and Buy
  cycles prove the composition before device work.
- Repository design tokens are inspected at their declaring owner before use.
  `MoolBrandGradient` is a semantic enum, not Flutter's `Gradient`; render it
  through the existing finite owner or build a `LinearGradient` from its
  authoritative `.colors`, then run focused analysis before tests.
- Search Console indexing alerts are reconciled example-first. A historical
  HTTP URL that now permanently redirects to an indexable HTTPS canonical does
  not authorize removing intentional utility-page `noindex`, changing healthy
  source or redeploying identical content. Prove the current redirect, headers,
  canonical, robots and sitemap, run the SEO suite, then validate only the
  exact stale reason while Google-controlled crawling remains pending.
- A transparent connected 44px rail is not professional visual acceptance by
  itself. Social, Buy, Eat, Ride, Book and Work use one adaptive tokenized
  native owner; variable-count families never stretch into an edge-to-edge
  strip, obscure content or change target sizing. The approved global rail
  remains visually anchored while destination and local content transitions
  behind one native shell, so a switch never feels like opening an unrelated
  page. Qualification requires cumulative predecessor and successor OPPO
  screenshots, real-user journeys, motion and reduced-motion proof, and
  founder device acceptance.
- Flutter container borders can deflate their child hit and text boxes. Clear-
  glass controls paint borders as non-deflating foreground decoration and
  directly measure every final InkWell at 48px or larger under 320px large-
  text fitment before any family rollout.
- Responsive navigation tests derive compact cluster widths from the shared
  token owner. At 320px the required 4px side insets produce 312px, not a
  duplicated hand-calculated width that silently erases an inset.
- InkWell press feedback is sampled after its finite press-recognition
  interval, then released to prove one callback. Raw pointer-down alone does
  not establish that the pressed AnimatedScale target has activated.
- Formatter output invalidates remembered patch shape. Read exact current
  bounded snippets after formatting and retry narrow hunks; an atomically
  rejected combined patch is always no mutation, never partial success.
- Repository PowerShell gates run separately from the repository root and are
  admitted only by their own exit status and pass line. A later successful
  Flutter command cannot mask an earlier path or gate rejection.
- Test inventory starts with `rg --files` under one verified literal test
  root. Presumed subdirectories are not added to mixed-root searches, and any
  path rejection makes that search incomplete evidence.
- Shared navigation geometry must propagate through every family wrapper.
  Family-local fixed heights consume the authoritative rail-height token, and
  final wrapper, rail and keyed InkWell sizes are measured at 320px large text
  before family conformance passes.
- Regression entries reference only evidence and gates that already exist.
  Planned focused tests stay in the authorized ticket plan until their files
  are created; future paths cannot satisfy the permanent-memory checker.
- Label no-shrink gates inspect each real Text ancestor chain, not an entire
  subtree that may contain legitimate fitted SVG artwork. Provider assets have
  their own exact-count and attribution checks.
- Accessibility stress stays owner-specific. Full routes use the authorized
  navigation scale threshold, while isolated local rails prove larger system
  input clamps internally; unrelated catalogue/global owners cannot obscure or
  authorize expansion of a subaction ticket.
- Selected glass tinting preserves the base surface alpha. Family accent RGB
  may change, but a selection layer cannot silently make light or media glass
  more opaque and block more destination background.
- If evidence prose context is uncertain, create uniquely named evidence and
  patch the exact current registry tail. An atomic documentation-patch failure
  is no mutation and is registered before any runtime retry.
- Flutter analysis and test suites keep independent shell exit statuses. Even
  when an aggregate invocation prints two pass lines, it is diagnostic until
  each check is rerun and admitted separately.
- Windows evidence lookup uses literal ripgrep roots plus `-g` filters or a
  bounded `rg --files` inventory. A wildcard path rejection invalidates that
  evidence-search portion even when another operand returned source lines.
- Repository JSON validation runs from repository root, separately from
  package formatting, analysis and tests. Mixed working directories or one
  aggregate exit status authorize no host-cycle progress.
- AnimatedContainer geometry is measured from its rendered finder with
  `tester.getSize`; the widget instance is used for duration and decoration,
  not nonexistent width or height getters.
- Flutter test configuration and shard inputs are derived from `rg --files`
  under verified roots. Conventional config filenames are not guessed, and a
  missing-path read invalidates the aggregate command reconstruction.
- A selected-ticket manifest digest is coupled to every manifest lifecycle
  mutation. When qualification changes a manifest from selected to complete,
  recompute its literal SHA-256 and refresh the checkpoint before rerunning the
  delivery lock; a pre-execution digest cannot validate completed evidence.
- Build-provenance discovery never begins with a recursive search of the full
  immutable artifacts tree. Inventory scripts/config first and read only a
  selected artifact directory or known evidence file; an unbounded evidence
  search that times out is no provenance result.
- Windows dirty-tree sealing uses Git's directory-level untracked inventory
  plus exact tracked paths. `--untracked-files=all` is inadmissible when old
  artifact trees produce filename-too-long warnings, even if Git exits zero;
  hash the path-safe normal inventory and separately bind ticket source owners.
- Ticket `implementationDisposition` is a machine enum, not free-form prose.
  Copy only values admitted by the current delivery lock and express build or
  device evidence detail in coverage/scope fields; invented labels must be
  rejected before ticket execution.
- Active-build probes cannot search every process command line for literals
  that also occur in the probe command. Exclude the current PID and bind
  Gradle patterns to Java and Flutter-build patterns to Flutter/Dart/cmd
  executables before admitting a zero-process prebuild result.
- ADB `dumpsys` evidence stays line-wise until filtering is complete.
  Converting the full dump to one multiline string before `Select-String`
  makes any match emit the entire object; extract anchored identity fields
  first and join only the bounded result.
- UIAutomator bounds captures are strings. Cast each x/y endpoint to `int`
  before addition; otherwise PowerShell concatenates digits and generates a
  meaningless off-screen tap. Reject out-of-display centers and admit a
  capture only after two matching selected-semantic inventories.
- PowerShell variables are case-insensitive, including automatic variables.
  Qualification scripts never assign contract data to generic names such as
  `$host`; use a domain-specific name so the read-only `$Host` automatic
  variable cannot abort or ambiguously contaminate a host cycle.
- Permanent regression owners are discovered from a bounded `rg --files`
  inventory before use. Never infer a shortened registry filename; the exact
  verified literal owner must be read before composing a registration patch.
- A throwing PowerShell wrapper can prevent assignment of its already-emitted
  native output. Diagnose a rejected native phase directly with verified
  literal inputs, capture `LASTEXITCODE` immediately and print bounded output
  before any wrapper exception can hide the failing test or assertion.
- Flutter test inventories are resolved from a verified absolute repository
  contract and validated for their exact expected count before changing the
  working directory. An empty derived list must abort; it can never fall
  through to an unintended full-package `flutter test` run.
- Optional Windows process names are not queried as one combined `Get-Process`
  request. Enumerate and filter once, or normalize each optional absence
  independently, so one absent executable cannot make a partial probe fail.
- Replacing a shared capsule's typography or selected-state widget owner
  requires migration of every cumulative required-suite assertion before the
  first host cycle. Preserve family counts, fixed geometry, one-tap outcomes,
  selected semantics and reduced-motion behavior, but never regress accepted
  runtime tokens or architecture to satisfy stale implementation-shape tests.
- Transparent glass must be qualified as a composite, not by alpha alone.
  Freeze nonopaque smoked-base transmission and internal family-emission
  intensity so white icons and labels retain at least 4.5:1 across accepted
  light, bright, media and dark destination backgrounds in every family.
- Ticket authority inventories begin with bounded exact file discovery. A
  combined read containing even one guessed or missing manifest is incomplete
  and authorizes no runtime, build or device mutation.
- Permanent cumulative gates migrate their durable contract when a successor
  replaces an older design system. A C22 replay validates C22 capsule,
  placement, connector and legibility owners; it never forces the active C22
  ticket through a historical C21 sequential-selection gate.
- A Java Gradle daemon is not itself an active build. Prebuild process probes
  count exact Gradle client/wrapper main classes and actual Flutter/Dart
  build/test commands, while reporting an idle `GradleDaemon` separately and
  leaving it untouched.
- Repository PowerShell gates are invoked with an explicit `./scripts/...`
  path or a verified literal absolute path. PowerShell does not implicitly
  search the current directory, and a batch that stops after one preliminary
  check authorizes no qualification progress.
- Historical artifact owners come from exact machine-state evidence paths or
  bounded inventories. Never reconstruct an immutable predecessor directory
  from a descriptive ticket or design-system label.
- Ticket hierarchy roles do not imply filename suffixes. Discover parent and
  child manifests through a bounded config inventory and use only the returned
  exact literal owners before any authority mutation.
- Device screenshot evidence does not establish the next transition's live
  precondition. Reacquire the hierarchy immediately before every tap and
  deterministically reopen the required family when the device state changed.
- A fresh pre-tap hierarchy does not imply exclusive ownership of a live
  founder-held device. If another interaction replaces the family during the
  stability window, reject the journey and reacquire/reopen before retrying.
- Editor subactions that auto-open the keyboard require an explicit one-Back
  IME dismissal followed by proof that the same local selection remains current
  and `mInputShown=false` before full-screen evidence is accepted.
- Progress updates for a running sequential device batch report only pass lines
  already returned by the cell. Elapsed time never proves undisclosed later
  steps ran or passed.
- Polishing individual controls cannot rescue a navigation hierarchy that keeps
  two persistent action layers over destination content. Founder-rejected C22
  is replaced only through the ticketed C23 single-launcher/Home-hub model.
- Multi-file Add File patches are kept bounded and every content line retains
  its leading `+`. A parser-rejected patch is no mutation and must be
  registered before a corrected retry.
- Dense selected-ticket scope transitions are based on the exact current JSON
  and replaced as one validated document; broad multi-hunk patches must not
  depend on remembered or stale dependency-list context.
- New Dart edits are mechanically formatted with plain `dart format` first.
  Qualification then runs `--output=none --set-exit-if-changed` as a read-only
  no-diff gate before analysis/tests; no-output mode never writes normalization.
- Replacing a navigation render architecture includes analyzer-driven removal
  of every newly unreachable private field/method; focused analysis must pass
  before widget tests can qualify the replacement.
- Delivery authority owners are never addressed through descriptive shorthand.
  Use the exact robust delivery-lock path mandated by repository instructions
  or a bounded discovered literal; one missing operand rejects the whole audit.
- C23 selected-ticket scope transitions replace the exact verified complete
  scope JSON. Do not repeat broad multi-hunk edits after a stale-context
  prevention rule has already been registered.
- PowerShell Home-screen source variables use ticket-specific names such as
  `$moolHomeSource`; `$HOME` and `$home` are forbidden automatic-variable
  collisions just as `$Host` and `$host` are.
- A migrated interaction test also migrates its expected contract owner. C23
  family taps compare to the C23 six-family route matrix, never to an older
  default-route projection retained for a different acceptance boundary.
- PowerShell search patterns containing dollar-prefixed source identifiers use
  literal single-quoted arguments or fixed-string mode. Double quotes must not
  interpolate `$home`, `$host` or any other source token before ripgrep runs.
- A successor host-suite inventory includes every selected journey test's
  widget-key contract. C23 removes all C22 rail keys; migrate those assertions
  to the single destination launcher, zero rails, Home routes and continuity
  outcomes before cycle 1, never by restoring founder-rejected runtime UI.
- Regression-memory phases are read from the script's ValidateSet. C23 host
  test migration uses `implementation` with `BuildMode none`; `testing` is not
  an admitted phase and must never be guessed from the current activity.
- Migrating a persistent-rail tap to the vertically scrolling C23 Home hub also
  migrates reachability setup: find the exact key, `ensureVisible`, settle,
  tap, and then validate the route. Existence alone does not prove hittability.
- C23 stale-key inventories include family-specific prefixes such as
  `buy-local-tab-`, not only generic global rail names. Subaction continuity
  now exercises destination launcher -> visible Home target -> destination.
- A migrated Dart test verifies the defining import for each newly referenced
  type before execution. `BuyV2Destination` is owned by `buy_v2_models.dart`;
  the session import does not implicitly re-export it.
- A visually selected Home-to-Buy subaction must agree with the current router
  URI and retained return state. A missing `sub` query is diagnosed at the
  shared page-key/router owner; route assertions are never weakened to accept
  view/URI divergence.
- Query-specific main-destination states use complete-URI page identity so a
  new target cannot collapse onto an older same-path page. Origin-aware Home
  replacement and URI-aware page identity are one continuity fix.
- C23E1 Back tests distinguish root Home from destination-opened Home: root
  Home remains below a pushed target, while origin Home is replaced and Back
  restores the exact prior destination.
- PowerShell source gates treat Dart `${...}` tokens as literal text. Use a
  single-quoted PowerShell string with doubled embedded Dart quotes; never let
  `$state` or another Dart identifier interpolate in the gate process.
- GoRouter `replace` preserves current page identity; it is not the C23E1
  operation for replacing Home with a query-specific target. Use
  `pushReplacement` for origin Home and ordinary `push` for root Home.
- An unavailable execution cell has no result. Never infer qualification from
  a detached process; rerun the exact bounded checks from the preserved tree
  and retain long-cycle output in ticket evidence before relying on it.
- Repository scope and regression gates run from the repository root. Mobile
  Dart and Flutter checks run separately from `apps/mobile`; never combine
  both path domains under a mobile-relative `./scripts/...` invocation.
- A nested shell timeout terminates Flutter work; it is not a progress-yield
  control. Give analysis/tests a realistic timeout and use the outer execution
  yield to retain a live process while returning timely progress.
- `pushReplacement` plus complete-URI page identity does not by itself prove
  query continuity. When the visible Buy subaction and GoRouter URI diverge,
  trace target, redirects and destination synchronization to the single owner;
  retain the exact assertion and forbid stacked navigation workarounds.
- A provider/active-configuration hypothesis needs both measurements. If both
  report queryless Buy while an imperative page is visible, do not call either
  one the top-page owner. Inspect `GoRouterState.of` from the visible page; a
  base route-list URI cannot prove a transient-route collapse.
- For imperative push and pushReplacement journeys, visible-page
  `GoRouterState.of(context).uri` is the route-state owner. Provider and
  delegate base URIs are retained separately and never substituted for it.
- C23E1 Buy continuity asserts the visible keyed Buy page's exact path and
  `sub` query before and after router refresh. The underlying base `/app/buy`
  URI cannot create a false failure for a visible imperative Medicine page.
- Evidence amendments read each exact retained Markdown owner before patching.
  Registry wording is not assumed to match an evidence document's closing
  prose, and a rejected patch is registered before a corrected retry.
- C23 ticket transitions inventory bounded manifest candidates and match their
  exact `ticketId`. A child role or gate label never implies the manifest's
  filename.
- Host-qualification log sinks are resolved to absolute repository evidence
  paths before invoking nested scripts that use `Push-Location`. A missing
  complete pass seal counts as zero qualifying cycles.
- A C23 host cycle that reaches the brand gate but lacks its final fingerprint
  seal counts as zero. Audit the canonical brand component and exact gate source
  boundary before retry; never bypass or remove the retained brand gate.
- Brand source gates bind to the current component boundary and canonical token,
  not obsolete widget-call syntax. `_MoolHomeLauncher` must contain
  `MoolBrand.moolLauncherIcon` whether rendered directly or passed by name.
- Windows ripgrep searches use exact files, verified directory operands, or
  `--glob`; never pass a shell-style wildcard as a literal Windows path.
- C23H ticket and preselection evidence filenames are independently
  discovered. Inventory bounded `*C23H*` evidence owners before selection and
  never derive an evidence path from the ticket manifest name.
- APK dirty-tree seals use default path-safe porcelain inventory and reject any
  stderr warning. Never force deep untracked traversal through retained
  evidence trees; hash sorted owner records without deleting or altering them.
- A truncated or detached positive machine-gate invocation has no result. Prove
  the candidate APK and provenance are absent and the one-build authorization
  remains unconsumed, then retain a bounded rerun pass line before invoking the
  unique build wrapper.
- Evidence registration never guesses a prior regression document's filename.
  Inventory the bounded owner directory first and treat every PowerShell error
  record as a rejected compound inspection even when the process exit code is
  zero.
- Bounded complete-file paging discovers the current line count after the most
  recent mutation and constructs non-overlapping ranges from that value. A
  pre-mutation count is never asserted as current after memory is amended.
- JSON projections are diagnostic only and never supply `apply_patch` source
  context. Read the literal current owner, preserve minified-versus-formatted
  representation, and patch state owners independently so one mismatch cannot
  hide which transition changed.
- The `$HOME`/`$home` prohibition applies to device-evidence parsers as well as
  host gates. Use ticket-specific hierarchy variables, and when post-capture
  parsing fails, preserve and read the existing unique capture instead of
  repeating the real-user action or overwriting evidence.
- `Semantics(button: true, excludeSemantics: true)` does not inherit a nested
  InkWell's accessibility action. Every outer semantic owner for the Mool
  launcher, Home Chat, six family buttons and 17 subactions must expose a tap
  action itself (or preserve the child's semantics); widget tests assert
  `SemanticsAction.tap`, and OPPO UIAutomator must report `clickable=true`.
- A physical coordinate tap cannot bypass a missing Android accessibility
  action. Stop the candidate matrix at the first such mismatch, preserve the
  installed checksum identity and captures, and require a separately gated
  successor before any later device journey.
- Reference-to-production inventories never combine a possibly blank source
  anchor with a broad multi-feature token search. Prove the exact declaration
  line first, then run separately bounded family/route/duplicate searches with
  declared zero-match handling; truncated output authorizes no ticket.
- A compact lazy ListView proves off-screen content by scrolling its keyed
  owner into view before asserting it exists. Initial construction is not a
  reachability contract, especially at large text scale.
- A one-tap destination test first asserts the domain state, then scrolls back
  to the selected-value owner and verifies its semantics. It never searches
  globally for text that is legitimately outside the current lazy viewport.
- Regression-state diagnostics run from repository root against the exact
  discovered `config/codex-development-regression-registry.json` owner. A
  mobile-relative command and a guessed `*-memory.json` filename are invalid.
- A forward lazy-list discovery helper is not reused for backward verification
  after a state rebuild. Reverse-drag the persistent keyed list within a bound
  until the earlier owner is constructed; only then may `ensureVisible` run.
- A local Flutter button `textStyle` is a complete resolved style, not a safe
  partial brand-theme merge. Include `fontFamily: 'Inter'` whenever size or
  weight is locally overridden, and inspect the rendered evidence label.
- A source machine gate is written from exact formatter-stable declarations,
  not conceptual acceptance labels. Confirm every token and its real owner
  before the first gate invocation.
- Historical Ride exposure and conformance owners preserve Bike/Auto/Cab
  meaning, routes and continuity, not rejected local/translucent rails or a
  Home-root round trip. Current acceptance uses contextual choices and the one
  connected MoolSocial launcher.
- Destination-first vertical homes use a bounded keyed scroll helper for lazy
  package outcomes. A generic immediate-presence tap helper cannot prove
  off-screen package reachability.
- A Flutter `SemanticsHandle` is disposed inside the test body's `finally`,
  before binding end-of-test verification. Ordinary `addTearDown` timing is
  too late for this resource.
- A formatted test is reread literally before an exact patch. Regression
  registration/evidence is applied separately from source correction so one
  stale context cannot reject the whole record.
- A loop invoking PowerShell `.ps1` gates checks `$?` immediately after each
  call under stop-on-error. `$LASTEXITCODE` is only for native processes and a
  null value never converts a passing PowerShell gate into failure.
- Redundant-brand cleanup inventories custom painters as well as widgets and
  semantics. Buy must not draw `Mool`/`Social` into a header bitmap after its
  brand tile is removed; the connected launcher remains the single focal point.
- Brand contracts migrate with accepted chrome ownership. App-wide MoolSocial
  identity stays canonical, while a destination-specific gate cannot require a
  removed 104px title owner after the accepted 44px contextual slot replaces it.
- The canonical Mool service glyph and the connected MoolSocial launcher are
  separate brand contracts. The central connected launcher is exact text-only
  `MoolSocial`, 56px high and semantic; it must not regain a duplicate glyph.
- A protected-runtime baseline inventory mismatch is a material gate, even if
  focused UI tests pass. Never replace or bypass it from an unrelated service-
  home ticket; stop runtime mutation and require explicit reconciliation of
  every added and changed protected owner.
- Successor protection never overwrites the approved Social/YouTube baseline.
  It inventories the unchanged filtering boundary, runs the complete affected
  test set, and records a separate exact candidate seal pending device review.
- A PowerShell `finally` cleanup must not mask a native Flutter exit. Capture
  `$LASTEXITCODE`, restore location, then rethrow/exit with the captured result.
- Screen04 and Social/Buy compatibility preserve customer content, direct
  routes, semantics, targets and continuity—not removed Home/global/local rail
  widgets or their internal glass-animation keys.
- A pre-connected-shell Social golden is isolated and visually diffed before
  update. Shared chrome may migrate only when Social business content and
  layout remain unchanged.
- An affected Flutter suite resolves every intended test owner from
  `rg --files test` before invocation. Descriptive notes are not path authority;
  missing test paths reject the cycle and never count as qualification.
- Compact service-home tests scroll the keyed vertical list to each later
  wrapped choice before measuring its target. A lazy child that is not yet
  constructed is a reachability step, not evidence that the production control
  is absent.
- Booking price tests read the retained session switch before asserting an
  amount, then require the same truth in state, provider semantics and CTA.
  Reference-screen prices and remembered amounts are never production truth.
- A Wrap does not make a nested Row's long metadata label adaptive. Shared
  service metadata must give its Text a flexible, soft-wrapping owner so exact
  fee, availability, verification and cancellation truth survives 320px at
  140% text without clipping or overflow.
- REG677 applies to shared primitives as well as destination-local buttons.
  Any `FilledButton.styleFrom(textStyle:)` must explicitly retain Inter, and a
  capture with Ahem blocks is rejected even when semantic text tests pass.
- Source gates copy the final formatter-stable literal owner. Constness may be
  inherited from a parent and visible labels may live in conditional branches;
  neither syntax is reconstructed from a conceptual acceptance phrase.
- Product-family test discovery uses an explicit owner manifest when a shared
  word crosses domains. Personal `Book` services and Retailer `books` records
  are not one scope merely because both filenames contain `book`.
- Repository inventory and mobile analysis are separate invocations in their
  exact working directories. A later successful native command must never mask
  an earlier PowerShell/ripgrep path failure in the same compound diagnostic.
- A queued child outcome never implies its manifest filename. Resolve the exact
  ticketId with a bounded config search, require one manifest, and stop the
  inspection command immediately if any selected owner is absent.
- An explicitly authorized family addition updates every current action
  manifest and direct-route test in the same child ticket. Historical isolated
  component counts may change as compatibility data, but rejected local rails
  remain absent from the production shell.
- Cross-language owner inventories prefer separate fixed-string searches over
  one dense alternation. A ripgrep regex parse error is a rejected inventory
  and cannot authorize count or manifest edits.
- Forward-only lazy-list target manifests follow the literal top-to-bottom
  widget order. Measure above-the-fold geometry before advancing and never ask
  the forward helper to recover an evicted earlier owner.
- Data-driven truth tests are gated by their exact literal inventory plus the
  shared `contains(truth)` assertion. A source gate never expands that loop into
  per-value matcher syntax that does not exist.
- A shared router inside a protected product boundary changes that product's
  identity even when the new route belongs to another family. Preserve every
  prior seal and require a separately tested successor candidate.
- Auxiliary per-file manifests validate every hash as exactly 64 lowercase hex
  characters before sealing. A malformed predecessor line is reported and the
  enforced aggregate tree remains the predecessor identity authority.
- A transient execution-cell identifier is not durable test evidence across
  context compaction. Probe it once; when it is absent, record the loss and
  rerun only the bounded command. Resolve the regression registry through the
  repository inventory and inspect its top-level properties before selecting
  entries; do not guess a filename or JSON property.
- Shared behavior does not imply shared widget-key identity across retained
  compatibility owners. Read each owner's actual key namespace and assert the
  same customer action IDs and one-tap outcomes without importing keys from a
  different production scaffold.
- A predecessor absence test must be migrated when the founder explicitly
  reverses that placement contract. Preserve its adaptive, target-size,
  reduced-motion and route-outcome coverage against the new direct local rail;
  do not keep asserting the removed large launcher or absence of local actions.
- A main-actions-only Home opens each family's declared default route in one
  tap. Default-landing tests assert the exact owner plus compact launcher and
  destination-local rail; they never search Home for a second subaction button.
- A canonical family route and its explicit default-subaction route may be
  distinct strings that resolve to the same production owner. Test each route
  contract and observable owner independently instead of asserting string
  equality between aliases.
- Global navigation history tests follow the current division of ownership:
  the compact MoolSocial menu exposes main families, while each destination
  exposes its local actions. Preserve Back, deep-owner and active-session state
  assertions when replacing old launcher or centralized-subaction finders.
- Motion-containment tests measure the currently rendered shared shell, not a
  removed Hero or large launcher. Keep equal anchor geometry, finite production
  duration and immediate reduced-motion outcomes while using direct local and
  one-tap main-family controls.
- Removing Fade/Slide widgets is insufficient reduced-motion behavior when the
  route still lives for the standard transition duration. Accessibility mode
  sets both route directions to zero duration so old and new destination
  shells never overlap, while standard mode retains the finite production time.
- Cross-family Back-history tests require the current compact shell and both
  families' local rails to remain visible. A main-family switch is one global
  menu tap; native Back must still restore the exact prior subaction owner
  without visiting Home.
- Shared route-test helpers must encode the same ownership split as production:
  one compact-menu tap reaches a family's default, and a nondefault subaction
  is selected from the destination-local rail. Default actions never incur a
  redundant local tap.
- Current runtime presentation is compared to the active projection contract,
  not frozen historical labels. Historical root tests retain their safety and
  authority boundaries while one-tap routes follow the current approved names.
- A motion range in the projection must contain the retained runtime standard,
  and a machine-readable gate cross-checks both values. A passing widget test
  cannot mask a contradictory config maximum.
- Contract-value changes inspect every transitively invoked gate for hardcoded
  expectations and update the active contract plus all active checks together.
- Parallel diagnostics use all-settled evidence capture. If fail-fast
  orchestration rejects before returning sibling output, every unreported
  sibling is rerun and cannot be counted from assumption.
- A passing migration file whose path matches a protected inventory triggers an
  immediate delta audit and successor reseal before any aggregate gate. Update
  the pending-successor baseline and all expected-hash checks together.
- Exposure tests for a destination family preserve their service owners,
  forbidden legacy actions, one-tap completion and Back behavior while
  asserting the current compact local rail on every direct production route.
- Travel production helpers distinguish the historical three-ride projection
  from the current four-action rail. Bike, Auto and Cab retain RideSession and
  route truth; Bus is additionally required as the reused Book owner exposed
  directly under Travel.
- Care production coverage distinguishes historical Book evidence from current
  presentation. Doctor and Salon retain Book owners, Medicine retains the Buy
  owner, and Bus is absent because its existing Book owner is exposed only in
  the Travel family.
- Work production coverage keeps Earn Today as the one-tap family default and
  Workspace as one direct local tap. Both controls persist on each Work route;
  deprecated Delivery Work, Onboard and Verify actions remain absent.
- Comprehensive intent tests migrate only stale production navigation steps.
  Existing product/package/route outcomes remain unchanged; category coverage
  follows Travel Bus and Care Medicine ownership without duplicating either.
- Huge preserved dirty-tree counts capture Git stdout and warning stderr
  separately. Require a zero exit code and report only bounded counts; do not
  flood task evidence with already-audited long-path traversal warnings.
- A truncated mutation result has unknown outcome. Read every intended durable
  owner back with bounded output, verify exact state and evidence paths, and
  patch only confirmed missing deltas before continuing.
- Optional text discovery never leaves ripgrep exit code 1 unhandled. Use
  `Select-String` or explicitly accept the no-match result so a valid empty
  search cannot masquerade as a failed diagnostic.
- Versioned contract and gate-owner paths are discovered from repository
  inventory or the invoking script. Never guess a manifest filename from a
  ticket title before opening it.
- Multi-section patches keep every update hunk syntactically complete before an
  Add File section. Confirm an invalid patch applied nothing, then make one
  bounded corrected retry.
- Path discovery and owner inspection are separate steps. Once inventory
  returns the exact path, use that returned owner and remove every earlier
  guessed path from the subsequent diagnostic.
- A child gate that must be replayed by its successor supports an exact
  completed-child branch tied to the parent registry. It keeps all substantive
  product and protection checks and accepts only the lawful successor state.
- Selected-ticket implementation dispositions use only the delivery lock's
  exact machine-readable vocabulary. Validate the narrowest supported value
  before sealing ticket, scope and preselection evidence.
- Patch compact JSON from its exact raw line. Converted-object output confirms
  values but must not be used to assume whitespace or line layout.
- Host-qualification aggregates gain an exact completed-child replay branch
  for their named device successor before the host ticket closes. Contract,
  inventory, seal and installed-predecessor assertions remain unchanged.
- Complete active and successor-replay gate design before host cycle 1. Any
  later mutation inside the fingerprint scope supersedes every earlier cycle
  and requires two fresh cycles in a new immutable evidence directory.
- Adding a state branch requires auditing every later assertion in that gate,
  not only its primary identity predicate. Exercise the complete successor
  replay path and all nested gates before the final fingerprint cycles.
- Critical APK machine state is patched in small exact sections. After any
  rejected multi-section patch, prove no machine field changed, reseal all
  dependent hashes/counts, and only then run the positive build gate.
- A successful build does not imply install readiness. The separate immediate
  preinstall audit requires zero active Flutter, Dart, Gradle and Java process;
  any active process holds install closed without killing or bypassing it.
- Regression gate arrays contain only existing repository-relative files;
  human-readable audit labels stay in prose/evidence. An active held device
  ticket retains only the minimum reference authority required by scope while
  runtime, backend, build, install and external authorities remain closed.
- Cross-owner actions inherit their projected main-family rail surface as well
  as its action membership. Device qualification compares the sibling routes
  side by side and rejects any destination-owner background that reduces
  Previous, Next or MoolSocial contrast, including Care Medicine and Travel
  Bus.
- Source-text validation does not claim rendered-copy coverage for dynamic
  templates. Validate the template and its complete data set together, or
  execute the rendered state before requiring composed customer headings.
- Repository PowerShell gates and native validators never share exit-status
  handling. Run the PowerShell gate alone with terminating-error semantics;
  check a native validator's exit code only immediately after that executable.
- Inline native validators stay minimal and avoid mixed-shell nested quoting.
  Validate JavaScript extraction and compilation in Node, then perform literal
  HTML owner assertions separately in PowerShell.
- Category completeness does not excuse first-viewport occlusion. On small
  phones, a family Home uses one compact Search/Chat/filter toolbar before the
  discovery feed; it does not stack a large heading, lead paragraph and full
  search field above categories. The toolbar dismisses while scrolling down
  and returns immediately when scrolling upward.
- The later founder zero-height rule supersedes the REG857 compact-toolbar
  mitigation: family-home Search, Chat and Filter controls consume zero normal-
  flow height. Place them inside a safe overlay region of the first discovery
  surface, and expose categories only through a transient dismissible overlay.
- The later one-handed rule supersedes REG858's top overlay and category sheet:
  family Homes use mixed vertical feeds with category identity inside content.
  Do not require Filter-before-action; customers scroll and tap the actual
  product or service while local destination actions stay in the bottom rail.
- Mixed feeds do not retain a duplicated `Start in` action gateway. Each Home
  card is the actual customer target and opens its exact detail or booking state
  directly; the bottom rail is an optional family-mode switcher, not a required
  step before feed content.
- Ripgrep patterns beginning with a hyphen always follow the `--` end-of-
  options delimiter. Otherwise a valid source search can be rejected as an
  unsupported command option before inspecting the file.
- Never embed JavaScript template expressions or escaped HTML quotes inside a
  PowerShell double-quoted ripgrep pattern. Exact source literals use raw
  PowerShell `Contains` or `Select-String`; ripgrep receives only shell-safe
  patterns.
- PowerShell validators do not place `:` immediately after an interpolated
  variable name. Delimit the variable explicitly when interpolation is truly
  needed; fixed owner maps use raw literal arrays with `Contains`.
- Do not solve category-space or thumb-reach defects by deleting founder-
  required YouTube-style categories. Every family Home combines visible top
  categories, zero normal-flow height, an optional one-thumb horizontal swipe
  on the hero, default All content and direct transaction-ready cards.
- Source discovery is bounded before execution: search exact known owner files,
  cap displayed matches and avoid ambiguous in-memory Split pipelines. Do not
  scan a complete documentation tree when one prototype and one evidence owner
  can answer the question.
- A multi-pattern `Select-String -Context` command is not bounded by limiting
  match objects because every match expands into context records. Inspect one
  exact owner or one verified numeric line range per command.
- The main-family and local-action ownership split is exclusive: Social, Shop,
  Food, Travel, Care and Work live only in the compact Mool menu, while the
  current family's Home and every truthful subaction live in one horizontally
  scrollable bottom rail. The Home feed remains directly actionable.
- Multi-file PowerShell metadata projection always collects statement-form
  `foreach` output in a ticket-specific array before formatting. A direct
  foreach-to-pipeline parser rejection proves no owner inventory and blocks
  ticket selection or reference mutation until the corrected read completes.
- PowerShell HTML-owner searches use single-quoted ripgrep fixed-string
  patterns with repeated `-e` options. Do not send escaped double quotes inside
  a double-quoted alternation regex across the shell boundary; a regex parser
  rejection proves no source read.
- In-app browser `expectNavigation` receives an exact absolute URL string, not
  a regular expression. If the wrapper rejects an assertion, inspect the live
  URL before acting again because the triggering click may already have
  completed.
- If the Computer Use runtime lacks the skill-documented `sky.documentation`
  method, read the skill-owned guidance, confirmations and API files directly
  before acting; never infer UI-control signatures.
- A policy-blocked visible browser `Start-Process` is not retried through other
  shell syntax. Use the supported app launcher, or show the validated local URL
  in the in-app Chromium browser.
- If the Computer Use app launcher fails once, retry only once as documented,
  refresh the app inventory, and stop when the target still has zero windows.
  Do not guess alternate Windows UI launch paths.
- Social Shorts device acceptance requires both visible edge-to-edge geometry
  and exported Android semantics. Reuse the accepted bottom-clearance owner;
  every Home, Shorts, Create, Feed, Chat and Mool target must export at least
  44 logical pixels before a founder review candidate can pass.
- Customer UI never explains internal delivery state. Roadmap, gate, provider,
  API, OAuth, Firebase, scope, lifecycle, simulation, persistence, test-target
  and implementation language stays in tickets and evidence. An unavailable
  future capability is hidden; the available customer outcome remains direct.
- Once an exact evidence owner is known, do not combine full-file reads with a
  broad documentation-tree search. Read one bounded owner or source range per
  command so a tooling timeout cannot masquerade as missing product evidence.
- A successor scope-state transition is patched from the exact current JSON,
  one bounded block at a time. A rejected multi-hunk patch is verified as a
  no-op before rereading state, recomputing its ticket hash and retrying.
- Source-range discovery uses complete class signatures, not shared prefixes.
  Require one scalar start and end line before indexing a bounded range.
- Prohibited-copy absence is an expected empty result. Use a no-match-safe
  check and fail only on actual search errors or returned forbidden text.
- Rendered-copy snapshots use bounded fixed pumps. Do not wait for global
  animation quiescence when a loading or decorative state schedules frames.
- OPPO SafeArea geometry tests inject both padding and viewPadding through
  MediaQuery; setting only the synthetic test view is not acceptance evidence.
- Exported-semantics clearance expectations call the shared token owner; do
  not hardcode a lift inferred from remembered rail heights.
- A widget-test SemanticsHandle is disposed immediately after the bounded
  semantics inspection, before the test returns or continues other journeys.
- Compacted descriptions of registry owners are contextual hints, not exact
  paths. Resolve an uncertain filename once with a bounded repository file
  index, then reuse the exact codex-development registry and memory paths.
- A shared navigation function used by any production owner is a production
  API, not a visible-for-testing seam. Promote the existing single owner before
  reuse, and require full Flutter analysis in every successor host cycle.
- Regression `gates` arrays contain only verified existing repository-relative
  files. Human-readable command labels belong in the mistake, prevention or
  evidence narrative, never in a path-enforced machine field.
- A permanent customer-copy rejection updates every protected test owner, not
  only the focused journey. Search old exact literals across the bounded Social
  test set, expect finished recovery copy, and assert rejected commentary absent.
- Once the complete dirty tree is reconciled and preserved, successor evidence
  reads stay bounded to branch, HEAD and named ticket paths. Do not append an
  unrestricted full dirty-status replay to a small manifest query.
- An APK build-source manifest contains only stable runtime and protected test
  owners. Ticket selection, MVP state, regression records and qualification
  evidence stay outside it so candidate registration cannot invalidate source.
- A newly installed Google Cloud CLI must be resolved in the same shell that
  will invoke the wrapper. PATH discovery may fall back only to the exact known
  installation path; a final no-token context check must actually execute after
  the live build manifest is sealed. A failed wrapper candidate is never retried.
- APK prebuild is a workflow stage, not a valid regression-memory Phase value.
  Before composing the gate call, use the declared build phase with profile
  mode; never infer parameter values from stage labels.
- Windows APK qualification checksums the resolved evidence owner and may use
  one repository-local short-path hard link, created with an extended-length
  source path, for aapt and apksigner only after proving equal SHA-256 and byte
  length. A path rejection is not package, version or signature evidence and
  never opens installation.
- Device-evidence parsers use candidate-specific hierarchy names such as
  `$c29iHomeHierarchy`; `$HOME`, `$home`, `$Host` and `$host` are never assigned.
  A post-capture parser failure resumes from the retained XML without repeating
  the already completed navigation action.
- Chat and every other standalone non-compact `MoolGlobalNavigationV2`
  consumer reuse the Android exported-semantics clearance already owned by the
  destination system. Compact destination rails receive it only from their
  wrapper. Founder handoff requires real Chat UIAutomator height of at least 44
  logical pixels, not only widget-model coverage.
- Android navigation geometry tests inject matching OPPO bottom `padding` and
  `viewPadding`, plus synthetic View padding, before evaluating SafeArea. The
  exact exported-root intersection must prove at least 44 logical pixels for
  compact and standalone paths separately.
- Social navigation changes update every protected viewport and exported-
  semantics label inventory, not only focused Social journey tests.
- Social self-route and motion-containment tests assert the current single
  Social dock owner and explicitly reject the removed destination-shell key;
  route, Back and switcher lifecycle assertions remain unchanged.
- Bounded PowerShell line reads use the format operator or explicitly delimited
  variables; a colon never immediately follows an interpolated variable name.
- Provider-backed device journeys poll the existing loading screen to a bounded
  terminal content, empty or error state. They preserve intermediate evidence
  and never repeat a completed navigation tap because a fixed delay elapsed.
- Multi-file PowerShell inventories collect `foreach` output into a candidate-
  specific array before piping it to formatting or selection commands; a bare
  pipeline never follows the loop statement directly.
- Duplicate-owner searches first resolve exact paths from `rg --files` and
  pass only confirmed repository owners to ripgrep; conventional optional
  directories are never assumed as positional inputs.
- Selected-ticket assessments use only the delivery lock's enumerated
  implementation dispositions. Native presentation, shared-core and focused-
  test detail belongs in owner inventories and the necessity proof.
- Ripgrep file globs on Windows use `-g` against a confirmed directory, or an
  exact `rg --files` inventory; wildcard filenames are never positional paths.
- Before each Windows ripgrep call, every positional input is checked for `*`
  or `?`; any such input is replaced by a confirmed directory plus `-g`.
- New Flutter forms reuse the workspace's current `RadioGroup<T>` idiom,
  brace conditional branches and remove redundant imports before analysis.
- `RadioGroup<T>.onChanged` stays non-null in the current SDK; busy forms block
  interaction around the group and guard the callback instead of passing null.
- Creator forms verify the exact 412x915 viewport, constrain status text,
  provide local Material ink surfaces and keep recovery copy beside its action.
- Mobile dropdowns with long customer labels use expanded field layout and
  remain covered at the exact 412x915 viewport.
- Protected MoolSocial publication tests traverse the explicit hosting choice
  before asserting the workbench; YouTube and MoolSocial ownership stay split.
- C29E asserts both capability-enabled creator hosting choices, selects the
  MoolSocial host, and only then inspects MoolSocial format controls.
- Optional copy-gate companions are resolved through `rg --files`; no machine-
  state filename is inferred from the focused test's name.
- Focused Flutter analysis includes every new or modified Dart test file, not
  only product owners, and removes imports reexported by `flutter_test`.
- Backend package commands use local paths from `backend/functions`; repository-
  relative Git paths run only from the repository root.
- Evidence directories are inventoried in a completed command; later reads use
  only exact returned filenames, never a pre-guessed result name.
- Host qualifiers distinguish in-process PowerShell gates from native tools:
  PowerShell success is return-without-terminating-error, while LASTEXITCODE is
  read only immediately after a native executable invocation.
- Ticket-local host qualifiers fingerprint their enumerated owner set. A
  pre-existing dirty global UI-lock mismatch is preserved and reported under
  its own gate; it is never restored, resealed, waived or called a ticket pass.
- Provider-backed UI capability fixtures must be constructible by the real
  runtime controller. Private YouTube upload uses the single `privateUpload`
  profile for upload-purpose consent and its minimum exact-channel status; it
  never requires the mutually exclusive `ownerConnect` profile at the same
  time.
- Regression registry gate paths come only from an exact completed file
  inventory; a production owner's sibling test filename is never inferred.
- Multi-file patches use exact inspected prose anchors and keep optional
  evidence-document updates separate from product code changes.
- `gcloud config list` uses no multi-property positional argument list; Dev
  context reads project/account through an explicit output projection and
  never request an access token or credential value.
- Host source fingerprints contain stable executable product, test and gate
  owners only. Living ticket, scope, regression and protected-device files are
  validated and retained as separate per-cycle state hashes.
- Absence-expected ripgrep checks run as dedicated assertions: exit 1 is the
  required empty result, exit greater than 1 is a tool failure, and any returned
  prohibited text fails explicitly. Never make such a search the terminal step
  of a formatting, inventory or evidence-read compound command.
- C29N repository searches run from the repository root with repository-relative
  paths; Flutter commands run separately from `apps/mobile` with package-local
  paths. Do not mix those two coordinate frames in one shell call.
- Fixed-height global edge controls do not add a nested vertical card inset
  around `MoolDestinationIconLabel`. Their white Material surface retains the
  full shared rail height, and exact-viewport tests reject all layout overflow.
- A three-fixed-cell destination rail adapts Mool, family root and Chat together
  to 44 logical pixels at widths of 340 or less, while retaining 54 elsewhere.
  The 320x568/140% complete rail must leave the local owner its required width.
- Protected navigation tests derive rendered fixed-cell width from the shared
  viewport function and inventory the right-edge Chat successor; the 54-pixel
  constant remains the non-compact default, not an unconditional render width.
- Windows ripgrep navigation inventories use a confirmed exact directory plus
  `-g 'mool_*'` or an exact `rg --files` list. Wildcards are never positional
  paths, and search calls remain separate from completed evidence reads.
- Protected Social tests migrate atomically with a founder-approved successor:
  no universal Social utility header, current fail-closed provider copy, seven
  direct plus outcomes, Feed-to-Text, and no dock while a composer is active.
- Dart imports are not transitive. Rewritten tests directly import the declaring
  library for every referenced public design or widget type, and focused
  analysis runs before any qualification retry.
- A structurally rewritten protected test reconciles its complete import block;
  adding the new declaring owner also removes superseded imports. Zero-warning
  focused analysis is required before the test or host cycle runs.
- Navigation tests separate the 58-pixel shared rail token from final child
  extent under exported-inset host layout. Rendered and semantic edge controls
  must be at least 44 pixels; exact child height needs an explicit host contract.
- Ticket source gates assert stable key/copy literals and the executed behavior
  owner, not one interchangeable Dart construction syntax such as an inline
  `Key(...)` versus a loop-built `Key(key)`.
- Composer header CTAs own a finite compact width and at least 44-pixel height;
  they never rely on ambient button style sizing under an unbounded connected-
  chooser host. Normal keyboard and chooser journeys both reject layout errors.
- Protected Create lifecycle tests keep Mool, Chat and the local dock absent
  during composition, close explicitly, then prove the restored gateway and
  connected chooser/Back behavior. They never tap a hidden composer-time dock.
- API-owner evidence is read one exact file at a time, with large owners split
  into explicit non-overlapping line ranges. Truncated multi-owner output is
  rejected before it can support ticket selection or implementation.
- A symbol-only inventory does not relax that boundary: every API evidence
  command names one exact owner plus one small symbol family or explicit line
  interval, and must complete without truncation before admission.
- API-owner line counts and absence-capable searches remain separate. Empty
  searches explicitly admit `rg` exit 1, while small owners are read literally
  instead of inferred from a guessed symbol family.
- A remembered class name never implies a source filename. Resolve its exact
  declaring owner from `rg --files` plus an exact class-symbol search, then read
  only the returned literal path.
- ADB inventory is a dedicated preflight. Package, activity, screenshot,
  semantic and input reads begin only after one exact authorized serial is
  present and host-qualified, and every later command uses that serial.
- A product patch edits one freshly re-read local region or one exact repeated
  mechanical symbol family. Distant UI, state, method and class changes are
  never coupled to one anchor set.
- Supported-viewport Social tests assert the descendant `MediaQuery` text scale
  before fitment. Narrow rows adapt or wrap at 140%; text-scale suppression is
  never used as an overflow repair.
- Source-shape tests read the exact package-local owner with a literal file
  path, or assert a non-empty injected fixture and its provenance. An empty
  compile-time environment default is never source evidence.
- Sequential viewport tests assert a clean exception state immediately after
  initial pump and after every transition, so a layout failure is attributed to
  the exact render state.
- Scroll-mutating proofs run after earlier position-sensitive journeys, or
  explicitly restore and verify the required position before the next tap.
- Navigation tests use the exact control key supplied by the tested host and do
  not assume a reusable widget's default key survives explicit host injection.
- Repository policy/source gates run from the repository root, while Flutter
  commands run separately from `apps/mobile`. A final successful child command
  never masks an earlier command-discovery error.
- Source gates assert stable contract literals plus the executed behavior owner
  and never require one interchangeable inline key construction when a test
  builds the same key dynamically.
- Parent PowerShell qualification commands set `ErrorActionPreference` to
  `Stop` and invoke `.ps1` gates directly. `$LASTEXITCODE` never sequences
  PowerShell scripts; it is reserved for native executables.
- Create tool controls own a text-scale-aware vertical extent with at least
  44-pixel semantics. They never clip or scale down text and never add taps or
  hide a format to repair 140% fitment.
- Repeated method signatures are never mutation anchors by themselves. A local
  patch includes the exact declaring class and method, then focused analysis
  runs before tests.
- Default Create-route audits prove the two-owner creator gateway first, then
  tap the explicit MoolSocial posting action before auditing the composer.
  They never bypass the YouTube-hosted versus MoolSocial-hosted choice.
- Qualification owner reads remain one exact file per command. Evidence
  discovery resolves a bounded filename set before searching content and never
  shares a command with a required owner read.
- Every source owner is line-counted before a full read. Large owners use
  explicit non-overlapping ranges; truncated output is rejected even when a
  needed declaration appeared before the truncation point.
- Strict TypeScript owners omit absent optional properties, narrow indexed
  access and guard Firestore results before use; focused typecheck precedes
  compiled tests.
- Cross-language patches are syntax-reviewed in the declaring language and
  immediately checked by that package's analyzer or compiler.
- Social tests inject their gateway, derive server-owned identifiers from the
  acknowledgement and never treat a static named fixture as a mutable retry.
- Large native test suites capture combined output, preserve the immediate
  exit status and expose only a bounded tail with totals; unbounded or
  truncated output is rejected.
- New Dart owners run targeted strict analysis before behavior tests, including
  repository constructor and nullable-collection style rules.
- When a registry entry already resolves an evidence path, read that literal
  file only; do not repeat a repository-wide evidence content search.
- On Windows, rg searches use a directory plus `--glob`; shell-style wildcard
  path operands are never assumed to expand.
- Host dependency probes run independently through `Get-Command` with explicit
  absence output; optional absence never becomes an unhandled composite error.
- Moving a production helper into test support includes a complete consumer
  import-use inventory followed by targeted strict analysis.
- Source gates assert freshly-read stable literals in their exact declaring
  owner, avoid formatter-sensitive full lines and prove delegated callbacks at
  the real host and leaf boundary.
- Media publish qualification jointly proves unique candidate paths, cleanup
  across transaction races, image signatures, local file-loss mapping and
  compatible decoded/base64 request ceilings.
- Review Social gateways exist only in test support. Production fails closed
  without its endpoint, and Firestore plus Storage direct-client rules are
  explicit deny-all owners.
- Test inventories apply the exact Dart/Social filename filter before sorting;
  capture, golden and failure artifact trees never enter broad output.
- Backend emulator helpers match the package CommonJS target and resolve local
  rules from `__dirname`; typecheck precedes emulator startup.
- Firebase emulator commands quote comma-separated `--only` values, expose the
  bundled JDK only to the child command and always use a synthetic local
  project ID.
- Dependency qualification requires zero high or critical audit findings.
  Safe patch overrides are pinned; unresolved upstream moderate lineage is
  recorded and re-reviewed before deploy.
- Ticket transitions replay the Windows rg directory-plus-`--glob` rule; a
  prior ticket's lesson never expires at the next inventory.
- Windows `rg` never receives a wildcard as a positional path. Search a literal
  directory and express filename selection with one or more explicit `-g`
  patterns; any partial output paired with a path error is rejected.
- Every reuse-manifest owner must exist before selection. Embedded component
  owners are resolved from exact imports plus `rg --files`, then shared
  literally by the manifest, scope, tests and source gate.
- C29R source audits count each owner and read one explicit bounded range per
  command. A combined full-file and range read is never accepted after output
  truncation, regardless of command exit status.
- Dense deployment-owner reads use small, non-overlapping exact ranges and
  confirm coverage through the known line count. A truncated range is rejected
  in full and never supports a deployment-scope or mutation decision.
- Dirty-tree reconciliation never invokes `git status --untracked-files=all`
  in this evidence-heavy repository, even when the final object would be
  bounded. Use tracked-only status plus normal top-level untracked ownership;
  long-path warning floods invalidate the complete command output.
- C29R resolves YouTube backend owners from exact declarations in existing
  TypeScript files; semantic class names are never converted into guessed
  filenames.
- MVP and delivery gate names are likewise never converted into guessed script
  filenames. Resolve exact owners from `rg --files` before reading or invoking
  them; a missing positional path invalidates all partial search output.
- C29R preserves the inherited Social customer-copy test checksum mismatch and
  proves its own changed-owner allowlist. Immutable reference reconciliation is
  never folded into an unrelated quota/catalogue ticket.
- YouTube client tests reuse the exact `HttpTransportRequest` and
  `HttpTransportResponse` exports from `types.ts`; generic remembered names are
  rejected by focused typecheck.
- Regression entries reference only evidence and gate owners that already
  exist. A planned source-gate path is registered only after the script has
  independently passed.
- Dart formatting is applied explicitly before qualification. The no-change
  format check, analyzer and tests preserve their own immediate exit statuses;
  no later success may mask an earlier formatter delta.
- A predecessor source gate that hard-binds its own active ticket is not a
  timeless regression command. Successors protect prior behavior through
  focused tests and successor containment assertions unless an archival mode
  exists.
- Firestore transaction seams reject every read after the first queued write.
  Quota usage and operation-measurement documents are both read before either
  is written, for accepted and rejected decisions.
- Persisted measurement counters distinguish absence from corruption. Missing
  fields initialize to zero; present negative or non-integer values fail the
  write and can never silently reset quota evidence.
- ADB discovery runs alone and fails closed. No serial-scoped read, launch,
  test, build or install follows unless the exact serial appears once in
  `device` state; empty, offline and unauthorized lists stop immediately.
- New MVP ticket dispositions are resolved against the delivery-lock allowlist
  before selection. Deployment-only work uses the supported `configuration`
  disposition with `reuse` and `test_only_acceptance`.
- MVP authorization machine state uses only the gate-owned vocabulary. Exact
  founder-approved actions and exclusions live in the ticket authority,
  execution flags, founder-acceptance record and retained evidence.
- Successor disclosure-pending states also use only that same gate-owned
  vocabulary. Never coin a descriptive top-level state before reading the
  transition literals; keep authority nuance in the nested fields.
- Diagnostic owner reads run one exact literal path per invocation. A guessed
  owner or any nonzero child result rejects the complete diagnostic evidence.
- Regression-memory phases are resolved against the gate-owned ValidateSet.
  Dev backend and rules work uses `implementation`; later APK and OPPO work
  replays the separate `build` and `device` phases.
- PowerShell source-literal assertions use its native quoting rules. A literal
  containing double quotes is single-quoted; backslash is never treated as a
  PowerShell quote escape.
- PowerShell `rg -F` patterns containing `$`, quotes or parentheses are
  single-quoted and never allowed to become positional paths through expansion
  or backslash escaping. Any path error invalidates partial matches.
- PowerShell native gcloud filters also use one materialized string built from
  single-quoted fragments. Backslash-escaped double quotes are not a PowerShell
  quoting mechanism and may never justify a cloud-log conclusion.
- PowerShell native curl JSON bodies are likewise one single-quoted literal
  argument. A response paired with a curl URL/argument error is rejected in
  full and never proves endpoint authorization behavior.
- PowerShell `foreach` results are always materialized before piping, including
  small diagnostic/hash variant loops. A prior parser recurrence never expires
  merely because the next loop is read-only.
- Optional global runtime probes handle absence explicitly. Firebase emulator
  work resolves the repository-qualified bundled JDK and exposes it only to
  the child command; an absent global `java` is not an exceptional discovery.
- PowerShell switch values are not forwarded to a new `powershell.exe` process
  with colon syntax. Build a child argument array and append the bare switch
  only when true; strings are never relied on for `SwitchParameter` coercion.
- A founder-controlled cloud authentication window is an explicit checkpoint.
  Secured non-interactive commands do not poll it; they resume only after the
  founder confirms the visible authentication flow completed.
- A readable gcloud account/project configuration does not prove the secured
  access token is refreshable. On `cannot prompt during non-interactive
  execution`, open one visible founder-controlled login and make no secured
  retry until that checkpoint is visibly completed.
- Installed gcloud syntax is command-surface specific. Functions listing uses
  the locally accepted `--v2` flag; a rejected generation flag is never
  interpreted as empty deployed state.
- Native gcloud format projections are materialized as one literal
  `--format=json(...)` argument. Do not build the value as an inline
  parenthesized PowerShell native argument, and never suppress the child
  diagnostic before a deploy invariant is established.
- Generation flags are not transferred between CLIs: the installed Firebase
  `functions:list` rejects `--v2`, while the installed gcloud Functions surface
  accepts it. Each inventory preserves its own immediate exit status.
- A Firebase Functions inventory that returns only a generic project failure is
  rejected as evidence and is not treated as empty deployment state. Use the
  separately authenticated gcloud v2 metadata surface, then qualify Firebase
  deployment authentication at its own pre-mutation checkpoint.
- Successful gcloud reauthentication does not imply Firebase CLI readiness.
  Firebase `apps:list` is the independent pre-mutation checkpoint; on failure,
  inspect only bounded redacted diagnostics and require its own visible login.
- `gcloud config list` accepts at most one positional section, not a
  comma-delimited property list. Exact account/project/region discovery uses a
  format projection while credential and token payloads remain unread.
- Every line of an `apply_patch` `Add File` body carries the addition marker.
  A parser-rejected patch is treated as no mutation and registered before the
  corrected patch is issued.
- Multi-file patches repeat an explicit `Update File` header before every
  owner's hunks. A cross-file context miss is treated as no mutation and the
  corrected owners are syntax-verified before execution.
- This explicit-owner rule applies to every later hunk in the patch, not only
  the first correction. Before applying, map each context block to its literal
  path and open a new update header whenever the owner changes.
- Cloud metadata evidence must preserve stdout through the chosen wrapper.
  Empty composed shell objects are rejected; secret metadata uses one direct
  bounded command per owner and never reads version payloads.
- A cloud-inventory wrapper must also preserve the child diagnostic on nonzero
  exit. When only the wrapper exception is visible, retry the exact read-only
  child directly before parsing; never interpret the result as empty state.
- Cloud IAM owner discovery resolves the exact ticket/evidence filename set
  first. Broad docs/config/backend searches that time out or truncate are
  rejected and cannot justify a mutation.
- Deployment-package owner discovery also starts with the exact known gate
  owner. Never combine the complete docs tree with script and deployment
  directories in one search; a timeout yields no reusable inventory evidence.
- Optional evidence-path discovery treats `rg` no-match as an explicit absent
  result and never guesses a filename or directory. New binary evidence receives
  a ticket-owned explicit path while every existing artifact stays preserved.
- Firebase Console navigation verifies every refreshed accessibility and
  visible outcome. After a coordinate mistarget, use the current accessibility
  element where available and never continue from the wrong expanded category.
- Browser typing requires a freshly verified focused element. If a Firebase
  document index focuses Chrome's address bar, type only an exact authorized
  Dev console URL there; never send the intended field text to ambiguous focus.
- Chrome omnibox replacement uses `Ctrl+L`, refreshed focus, literal typing and
  Enter as separately observed actions. Generic accessibility `set_value` is
  not used after it leaves the original URL unchanged.
- A successful Computer Use call is not accepted without the refreshed UI
  outcome. If a labelled web control is a no-op, use one coordinate from that
  exact screenshot and verify the expected modal before continuing.
- Off-viewport Firebase dropdown options are selected only after scrolling the
  exact screenshot-bounded list until the intended row is visible. Continue is
  blocked until the closed combo visibly displays the intended location.
- A scrolled overlay invalidates prior coordinate offsets. Every Firebase
  location click is accepted only from the closed combo literal; any wrong
  region is corrected before Continue and never creates a bucket.
- Resizing or maximizing a window invalidates every screenshot-coordinate
  calibration. Reobserve and prefer the current semantic control; never infer
  a new coordinate from the displayed maximized bitmap.

- Full local qualifiers receive a realistic bounded process timeout. An early
  progress update is not implemented by terminating the qualifier after one
  second; a timeout run is rejected and repeated from the start.
- Complete backend suites use a bounded reporter for deploy qualification. A
  499-test spec stream that truncates tool output is not sealed even when its
  visible tail reports success; rerun typecheck, build and every test with each
  immediate exit status preserved.
- Function export gates track the truthful current source exports. After a new
  source-owned function is independently accepted and deployed, a stale
  two-export allowlist is corrected rather than interpreting the third export
  as an undeclared deployment target.
- A successful PowerShell script is not chained through an uninitialized or
  stale `$LASTEXITCODE` check. Invoke the self-contained qualifier directly, or
  reset the external exit code inside a checked helper before each child.
- An ignored Firebase runtime environment found before materialization is never
  overwritten, printed or deleted on sight. Record metadata/hash only and
  compare against a deterministic secret-free reviewed materialization before
  deciding ownership or cleanup.
- A provider-only backend redeploy never rewrites a historical approved UI lock
  merely because the full legacy package preflight sees the preserved newer UI
  tree. Use an explicit bounded provider-only qualifier that retains backend,
  runtime, export, secret-scan and patch-integrity gates; default behavior stays
  unchanged.
- Regression-memory patches use exact repository context already read from the
  file. Developer or conversation instructions are never guessed as literal
  repository lines.
- Preserved dirty-tree reconciliation never enumerates all untracked paths.
  Branch and HEAD remain scalar reads; tracked changes and top-level untracked
  owners are counted separately without printing the complete tree.
- Dense source audits are divided into exact small, non-overlapping windows.
  Truncated output is rejected in full and cannot establish machine-state
  vocabulary or authorize a transition.
- Regression memory uses only the AGENTS-owned registry and memory paths:
  `config/codex-development-regression-registry.json` and
  `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md`.
- A preserved untracked machine-state owner has no HEAD template. Resolve its
  current schema from the local file and its gate source; never accept a null
  Git-show summary as historical evidence.
- The delivery lock's required-selection switch is an active-execution check.
  Authority-pending closed scope runs the base delivery lock and closed MVP
  gate; exact authorization must precede the active-ticket selection check.
- `Tee-Object -Append` uses its `-FilePath` parameter set. A qualification
  cycle that stops on an evidence-log parameter error is rejected in full,
  preserves its partial log, and restarts under a new evidence filename.
- APK endpoint negative controls run from the exact active successor machine
  state. A historical default candidate may not mask the intended rejection
  through the MVP ticket/candidate binding.
- Flutter compact reporter output is evidence-captured and suppressed from the
  tool transcript. A truncated live transcript is not a sealed cycle even
  when the durable log and visible tail report success.
- Host qualification resolves Java through Flutter's configured Android
  toolchain when the global command is absent; absence alone never triggers a
  PATH mutation or duplicate runtime installation.
- A first-native hierarchy and screenshot must describe the same stable route.
  During retained-state restoration, preserve mismatched sequential captures
  and require two matching no-tap pairs before deciding C28D semantics.
- Social runtime diagnosis reads credentials, HTTP/error decoding and Feed
  exception-state owners in separate exact source windows; multi-pattern
  whole-owner context output is rejected when truncated.
- A rendered accessibility sentence may be assembled from source fragments.
  An exact no-match is recorded as absent; owner discovery retries with one
  shorter evidence-backed literal and never guesses a file.
- Play Integrity diagnostics never read or retain complete request lines.
  Exclude `nonce=` and request payload fields; use only bounded redacted
  completion, callback and error markers.
- APK review distribution is qualified against the exact App Check policy
  before build/install authority is consumed. A production-grade Play
  Integrity candidate uses a Play-recognized install, and Create writes remain
  blocked until that client completes a signed-in live Feed read.
- PowerShell statement-form `foreach` output is materialized in an explicit
  collection before it enters a formatter pipeline. A parser-rejected summary
  command provides no evidence and changes no state.
- The materialize-before-format rule is mandatory for every PowerShell loop,
  including small read-only inventories: assign `$rows = @(foreach (...) {
  ... })`, then format `$rows`; never compose a direct statement-loop pipe.
- Founder-facing Android release launchers and their build wrappers fail closed
  unless PowerShell major version 7 or newer is established before secret
  prompts or build-authority mutation. Windows PowerShell 5.1 native stderr is
  never allowed to consume a candidate merely by classifying a warning as a
  terminating `NativeCommandError`.
- Dirty-state reconciliation never captures NUL-delimited full status in a
  PowerShell scalar, never enumerates the complete untracked tree, and never
  combines status with a broad content search. Aggregated counts are reported
  only from an explicitly selected and validated numeric property.
- Release qualification rejects an Android generated plugin registrant that
  references any plugin marked `dev_dependency=true` while release Gradle
  excludes that plugin. Do not add test plugins to a production classpath or
  edit ignored generated output by hand; prove usage and correct the source
  dependency/generation owner under a new exact candidate.
- Installed Flutter SDK test owners are enumerated before content search. A
  recalled nonexistent SDK path invalidates the compound search result even
  when other owners return matches.

- Every MoolSocial readiness statement names its exact phase: pre-AAB source
  and build readiness, Internal candidate activation, post-install identity,
  complete live acceptance, or go-live readiness. Earlier phases never imply
  later ones.
- Automated tests are necessary and never sufficient for a production-grade
  claim. The exact Play-installed candidate receives adversarial exploratory
  real-user testing across real data, signed-out/signed-in, each provider,
  independent Email/Mobile OTP, cancel/error/retry/offline/relaunch/process
  death/system Back/provider return, accessibility geometry and customer copy.
- Codex actively searches for unexpected defects beyond the scripted happy
  path. Every mistake, false result and escaped defect is registered with
  retained evidence before continuing, then only an exact founder-authorized
  selected ticket may be implemented.
- `complete`, `production-grade`, `reviewer-ready` and `go-live ready` are
  forbidden while any mandatory live journey is pending/failed or any
  MVP-required blocker remains unresolved. Apply
  `config/moolsocial-production-grade-real-user-release-practice.json` for all
  remaining MoolSocial work through go-live and regressions after go-live.
- Evidence inventories use one explicit uniform row schema. Report `Exists`,
  `Length` and `SHA256` for every requested name; never interpret blank cells
  from a heterogeneous implicit PowerShell table as a zero- or one-byte file.
  Hash or read a candidate only after its exact `Test-Path` result is true.
- A parsed Flutter accessibility `content-desc` can contain duplicate or
  multiline action labels and multiple visible cards can expose the same
  action. Normalize it into trimmed semantic lines, match a complete action
  token, then select the intended enabled/clickable node by retained card
  context and exact bounds. Never fall back to a blind coordinate.
- Any Feed scroll invalidates the previous viewport's card context. Derive the
  intended current public author, card description and enabled/clickable action
  from the exact hierarchy captured after that scroll, then bind the tap to
  those retained bounds. Never carry a prior card identity into a new viewport.
- Required owner reads are sized by aggregate lines/bytes, not merely file
  count. Read one small file at a time and large files in explicit numbered,
  non-overlapping windows through EOF. A truncated window or grouped output is
  rejected in full and must be registered before a smaller retry.
- The dense `ACTIVE-CODEX-HANDOFF.md` owner is read in explicit 200-line,
  numbered, non-overlapping windows through its exact measured EOF. A
  truncated window is rejected in full before any smaller retry.
- Required regression-owner paths are resolved with a narrow `rg --files`
  inventory before reading. Never reconstruct a quality-document or registry
  path from memory when its exact durable filename can be discovered safely.
- Authentication contract owners are resolved by exact symbol search inside a
  verified existing root. Never add a convention-derived contract filename to
  a grouped read; any missing-path output rejects that diagnostic even if a
  later command masks its exit status.
- After a resume or context compaction, UI owner paths are re-resolved from a
  narrow current-tree `rg --files` result before reading. A remembered or
  summarized path is not repository evidence, and any missing-path diagnostic
  is registered before retrying.
- A changed Social action contract is searched across both exact symbol owners
  and the accepted focused-test manifest before the narrow suite is declared
  complete. A test claiming a signed-in actor explicitly starts and asserts
  `JourneySession`; a signed-in gateway fixture alone is not authenticated UI
  state.
- Qualification package roots and Hosting gate owners are resolved from narrow
  current-tree `rg --files` results. Never infer a conventional package path or
  reconstruct a test command from memory; read and invoke only exact returned
  owners.
- No-change Dart format audits target exact owned Dart roots (`lib`, `test` and
  verified local-package Dart roots). Never format an application root that
  contains volatile generated `build` or tool output.
- Optional `rg` discovery captures each query's output and exit status
  independently: 0 means matches, 1 is an explicit zero-match result, and only
  statuses above 1 are errors. Never put unclassified optional searches in a
  fail-fast grouped diagnostic.
- Sealing state and narrative evidence are patched one file at a time, or each
  hunk is preceded by an explicitly verified file header. A rejected patch is
  zero mutation and is registered before retry.
- After a restart or context compaction, required AGENTS owners, Git identity
  and the huge dirty-tree inventory are never grouped into one reconciliation
  read. Read each owner independently, measure dense files first, use numbered
  non-overlapping windows of at most 200 lines through EOF, and bound branch,
  HEAD and dirty-ownership evidence separately.
- PowerShell capture of `git status --porcelain=v1 -z` is not treated as an
  array of NUL-delimited records. For bounded reconciliation, parse validated
  line-delimited porcelain records and hash their deterministic UTF-8 line
  join, or use an explicitly verified raw-byte stream owner before relying on
  NUL framing.
- Dirty-tree reconciliation enables per-command Git long-path handling and
  captures stderr separately. Counts and hashes are admissible only when Git
  exits zero and the captured warning/error stream is empty; never allow a
  large long-path warning stream to share and truncate the evidence output.
- Prefer in-memory `System.Diagnostics.Process` capture for compact Git status
  evidence. Redirect stdout and stderr separately, read both streams
  asynchronously, and create no temporary files or cleanup operations when the
  diagnostic result can be computed entirely in memory.
- PowerShell required-owner metric inventories collect rows into an explicit
  results array before formatting. Do not pipe directly from an unwrapped
  `foreach` statement; a parser error is zero owner evidence.
- Manifest-relative approved-reference roots are not converted into screenbook
  filesystem paths by convention. Resolve the exact contract through a narrow
  `rg --files` inventory inside the authorized screenbook root before reading.
- A PowerShell machine-gate script that may call `exit` runs in its own shell
  process. Never append tests or later gates to the same command; admit a test
  only when its own runner output and exit code are present.
- Chat and Universal implementation owners are resolved through a narrow
  current-tree filename inventory before symbol search. Never add likely UI
  paths by naming convention, and reject every grouped rg result that contains
  a path error even when a later pipeline masks the native exit code.
- Dense Flutter source is inspected through exact, non-overlapping windows of
  at most 100 lines. A truncated source read is zero verification evidence and
  is registered before retrying with smaller windows.
- Regression memory registration is patched one owner at a time with exact
  freshly read context. A rejected compound patch is zero mutation and is
  itself registered before retry.
- Social implementation owners are resolved from a narrow current-tree
  filename inventory before any grouped symbol search. Never infer a Social
  consumer filename from feature naming.
- When a repair intentionally replaces a retired runtime behavior, update its
  exact authoritative focused assertion and add successor positive/negative
  coverage before the first test run. Never knowingly run a stale expectation.
- On Windows, ripgrep receives a verified directory path and filename filters
  through `--glob`; never pass a Unix shell wildcard as a literal path.
- Positive authenticated Social widget tests use a started Journey snapshot and
  assert authoritative `isAuthenticated` state before the action. An email
  display field alone is never treated as authentication.
- Chat no-send tests use zero outbound gateway calls and unchanged optimistic
  state as truth; they never require a seeded conversation history to be empty.
- Specific recovery validation runs before a broader validator when the exact
  invalid input is a subset of the broad rule; otherwise the intended recovery
  contract is unreachable despite safe rejection.
- Test owners are patched independently from exact current context. Never place
  a hunk marker between one file's final hunk and the next file header.
- Scope-state ticket selection is patched through small independent exact-
  context hunks. Never reconstruct a current classification sentence from
  memory inside a compound state replacement.
- PowerShell cross-owner searches use separate literal ripgrep patterns or one
  verified single-quoted expression. A regex parse error is zero evidence.
- Optional Dart gateway capabilities are resolved through an explicitly typed
  nullable adapter before method calls. Never assume an unrelated interface's
  members are exposed through runtime promotion of the base gateway type.
- Formatter, analyzer and test tools run in separate processes with every path
  resolved against the explicit workdir. A later tool can never mask an earlier
  missing-path or nonzero result.
- Focused analyzer evidence is split into small independent owner groups. A
  truncated tool result is no qualification evidence even when the requested
  target set was focused; admit only explicit completion and exit evidence.
- Regression-memory content searches target exact config/docs owners or a
  filename inventory first. Never search the repository dot root when large
  artifact trees can match and overwhelm the evidence channel.
- A repository interface expansion includes every production implementation
  and test double before typecheck. Test doubles receive method-specific state
  and assertions; incomplete or empty compatibility stubs are not sufficient.
- User-facing mutation bounds use operation-specific validation and recovery
  text in both backend and client tests. Generic field-invalid errors do not
  satisfy an explicit character-limit contract.
- Server-acknowledged child records retain and validate their exact parent
  identity in the client model. A comment page or reply result is rejected if
  any comment postId or acknowledged post id differs from the requested post.
- Formatter mutations invalidate previously read patch context. Reread exact
  insertion boundaries after formatting and patch new tests separately from
  helper edits; a rejected patch remains zero mutation.
- Every insertion patch is checked for explicit added lines and a stable
  anchor before execution. An accepted context-only no-op is still zero
  mutation and must not be mistaken for implementation progress.
- Insert-before patches contain only the new blocks followed by the untouched
  anchor declaration. Never copy, rename or replace the anchored test body to
  manufacture an insertion point.
- Never send a placeholder apply-patch call after selecting an anchor. Compose
  and visually verify the complete added block, its plus-prefixed lines and the
  unchanged anchor before invoking the edit tool.
- Any selected ticket JSON mutation is followed by recomputing its exact
  SHA-256 and resealing the authoritative selected-assessment manifest hash
  before the scope gate is replayed.
- Release-count diagnostics first locate the exact current nested JSON field
  paths. A null projection from an assumed top-level schema is no evidence and
  is rejected without inference.
- PowerShell ripgrep literals that contain source double quotes use single-
  quoted `-e` arguments. Any argument-split path error invalidates the search
  result and is registered before retry.
- Router owners are resolved from a narrow current-tree filename inventory
  before symbol search. Never add a likely router path from memory to a grouped
  command; one nonexistent path invalidates the combined evidence.
- Social widget call sites are read in a narrow exact current region directly
  before patching. Never reconstruct callback order or indentation from an
  earlier excerpt after nearby source mutations.
- Profile relationship controls with authentication-state copy are stacked
  below the flexible avatar/identity header. Do not place a long Follow action
  in the same bounded row as public metrics; prove compact/large-text fitment.
- Firestore index owners are resolved from firebase.json or a narrow filename
  inventory before content search. Never assume the standard index filename is
  at repository root.
- Adjacent test insertion anchors are reread after every formatter run. Never
  reuse a pre-format one-line declaration when Dart may have wrapped it.
- An insertion apply-patch is forbidden until its patch text contains the full
  new block and at least one verified plus-prefixed semantic line beyond the
  patch header. Selecting an anchor alone is never a tool-call boundary.
- Compact or large-text Feed author headers render the same semantic Message
  action as a tooltip-backed icon control. Fitment coverage uses a real
  authorId so the trailing action is actually present.
- Repeated test assertions are never used as the sole patch anchor. Include a
  unique test name, finder key or compact-specific adjacent statement and
  verify the resulting line location immediately.
- Widget diagnostics cap record count before execution and print only compact,
  stable fields. A truncated test result is zero evidence and is never used to
  infer the failing layout owner.
- After compaction or restart, exact regression-memory and source owner paths
  are resolved through a bounded current-tree inventory before direct reads or
  patches; summarized path labels are not repository authority.
- Routine regression-memory lookups read exact registry and quality-memory
  owners directly. Accumulated artifact roots are never searched for a known
  regression identifier, and every enumeration is capped.
- Complete backend qualification selects a bounded Node test reporter before
  execution. A verbose full-suite stream that the evidence channel truncates
  is rejected even if its final summary remains visible.
- A Node dot-reporter qualification captures the bounded stream, counts only
  reporter dots and emits that exact count beside the preserved process exit.
  Dot output without an explicit counted total is not final evidence.
- Large JSON owners are parsed and projected to exact bounded nodes for
  qualification. Never run text matching against one raw whole-document JSON
  record, because a single match can render and truncate the entire owner.
- The MVP scope gate's top-level `state` is a checker-enforced enum, not a
  progress label. Keep `ticket_disclosed_and_authorized` while source progress
  advances through manifest evidence and selected-assessment fields.
- Ticket searches use exact paths returned by a bounded filename inventory.
  Never pass a Windows wildcard as a ripgrep path argument after the exact
  owners are already known.
- MVP implementation dispositions are checker-enforced canonical enum values.
  Ticket-specific techniques belong under `adjustments`; never invent a new
  disposition label without reading the delivery lock vocabulary.
- Widget tests that assert `SemanticsAction` explicitly import its `dart:ui`
  owner. Do not assume Flutter test or Material imports re-export engine
  semantics enums.
- `SemanticsHandle` is disposed inside the widget-test body with `try/finally`.
  Never defer it through `addTearDown`, because Flutter verifies active handles
  before general teardown callbacks complete.
- After a symbol search returns an exact current line, subsequent reads are
  bounded around that line. Optional zero-match searches run separately with
  explicit absence handling and never invalidate required evidence.
- Every optional ripgrep absence check explicitly converts only exit 1 into a
  labeled no-match success and preserves all other nonzero exits. Never issue
  an optional raw ripgrep pipeline, including immediately after registration.
- Raw ripgrep is forbidden for expected-absence audits. Use exact-file
  enumeration plus `Select-String` and emit an explicit match count, or compose
  the exit-1 normalization before issuing the tool call.
- Large Flutter manifests use the JSON reporter captured in process memory.
  Qualification emits only parsed pass/skip/fail totals and the preserved
  process exit; compact carriage-return progress is never streamed directly.
- Flutter JSON qualification joins `testDone` to `testStart` metadata and
  excludes only hidden or synthetic `loading` events. It emits raw and filtered
  counts; never equate every successful protocol event with an authored test.
- Every release-state projection first enumerates the exact relevant object
  property names. Reject all nulls and report only verified non-null paths;
  prior release schemas are never reused from memory.
- Large qualification scripts are inspected one exact symbol at a time with
  capped matches, followed by only a 20-30 line read around the verified line.
  Never combine broad search output with a fixed large source range.
- Complex multi-owner qualification calculations live in a bounded,
  reviewable audit script added through `apply_patch`; they are not compressed
  into oversized inline PowerShell command arguments.
- Ticket projections enumerate every exact nested owner before accessing its
  fields. Verifying only the top-level schema never permits nested guesses.
- PowerShell task collections never reuse automatic variable names such as
  `$Matches`, regardless of casing. Use explicit collection names and filter
  once before reporting.
- Flutter JSON reporter fields that are optional are accessed only after
  explicit property-existence checks with documented defaults. Strict-mode
  parser exceptions invalidate the run before any retry.
- Bounded Git reconciliation uses exact branch/HEAD commands and disables
  untracked enumeration. Never scan the enormous user-owned artifact tree just
  to count untracked files.
- Deployment service-owner searches start with exact executable config,
  scripts and deployment manifests. Never include the entire historical
  quality-document corpus in the initial lookup.
- Web research orchestration uses plain query strings or correctly escaped
  literals. Never paste quoted search terms into an unescaped JavaScript
  string.
- Scope-state enum values are copied only from the exact current machine
  gate's allowed set. Descriptive prose is never assumed to be an executable
  enum.
- Selected-ticket evidence is created, parsed and existence-verified before
  its path is written into MVP scope state. Never reference an intended future
  evidence owner.
- Release-control scripts are patched only in small hunks after immediately
  verifying each exact target region. Never bundle unverified distant contexts
  into one multi-hunk patch.
- Large release-control additions are split into bounded patches and followed
  by exact path, size, SHA-256 and PowerShell-parser verification. A truncated
  patch result remains ambiguous until those checks pass.
- PowerShell `foreach` output is assigned to an explicit task collection
  before formatting or filtering. Never pipe directly from a statement form
  that the Windows shell parser can reject.
- Release diagnostics never contain a direct `} |` statement-form pipeline.
  Assign every loop result first, and reject a parallel batch in full if any
  constituent command has a parser failure.
- Release-state schema enumeration and value projection are separate calls.
  Author the projection only from returned current property names, assert all
  required values are non-null and reject every stale-schema expression.
- Add-file patches are checked line by line so every semantic content line has
  the required addition prefix. A rejected incident patch is zero mutation and
  is registered before retry.
- Required release-state validation is type-aware. Numeric zero is a present
  value, never an empty string; use reference-null checks and apply whitespace
  validation only to strings.
- Wrapper source gates require only exact verified implementation literals.
  For a boolean preserved in machine state, forbid mutation to true and rely
  on the state invariant instead of inventing a reset assignment.
- Release checks respect owner boundaries: secure launchers own prompt and
  selected-state checks, state gates own full version/package/branch identity,
  and wrappers own dynamic propagation. Never demand one owner's literal from
  another owner.
- Node 22 counted summaries accept only exact hash or information-symbol
  pass/fail prefixes and still require explicit expected integer totals plus a
  preserved zero process exit.
- Qualification logs are immutable per cycle attempt. Retries use an explicit
  attempt suffix, refuse existing log paths and never overwrite failed evidence.
- Immutable Screens 01-03 locks run before any login/account-handoff dependent
  edit and as the first candidate gate. Never reseal a changed hash or bypass
  the gate without the separate founder acceptance workflow.
- Locked-screen recovery reads one exact 20-40 line region per already located
  owner. Never combine wrapped cross-owner symbol output that can truncate the
  evidence channel.
- Immutable accepted tests are never extended for successor integration
  coverage. Put new handoff behavior in a ticket-specific non-locked test owner
  unless a separate founder acceptance workflow versions the locked test.
- Before extending a shared platform test, inspect the approved reference file
  list. Candidate release/plugin/Firebase assertions belong in non-locked gate
  scripts or separately versioned test owners.
- Machine-returned SHA-256 values are copied exactly and validated as 64 hex
  characters before durable registration. Never insert visual grouping spaces.
- A checksum correction is compared directly with fresh Get-FileHash output
  before it is patched or narrated; do not trust a visually edited literal.
- A locked-owner restore requires both zero Git diff lines and its exact
  approved SHA-256. Inspect the post-patch residual diff before any retry.
- Small encoding-variant diagnostics use explicit named byte arrays rather than
  compressed nested inline loops; a parser failure is zero evidence.
- Acceptance-owner lookups select exact screen id plus production-accepted
  status, assert one result and only then resolve its scalar path.
- Current successor qualification uses the timeless approved UI checksum gate.
  Historical acceptance scripts with old active-ticket assertions are invoked
  only for their exact ticket, not as successor gates.
- Flutter format, analyze and test run as separate processes with each native
  exit preserved after cleanup. A final Pop-Location may never mask failure.
- Focused Flutter files use a bounded named expanded test for diagnosis and a
  captured JSON counted wrapper for qualification, never streamed compact
  progress.
- YouTube channel entry records the stable Social Videos cancellation origin
  explicitly; never derive it from mutable tab state at the async boundary.
- The YouTube account control's recovery route is owned by its provider
  workflow, not by the composing home/tab widget. Use the explicit Videos path.
- Release work uses one authoritative gate or native action per shell call.
  Never combine the memory gate with format, analysis, tests or builds.
- If an explicit route value is lost after a session call, inspect the exact
  getter and canonicalizer before another caller patch; prove the session and
  end-to-end contracts together.
- JourneySession navigation getters are not interchangeable:
  authenticationCancelFallback owns router interception fallback, while
  readyRoute() exposes the active sign-in cancellation destination.
- Regression-memory gates with potentially large output are captured under a
  unique immutable attempt log and return only a bounded final summary. A
  truncated direct rendering is zero gate evidence and is registered before
  any retry.
- Post-restart dirty reconciliation never prints or enumerates the full
  preserved tree. Branch and HEAD are independent scalar reads; tracked status
  is captured in memory with untracked enumeration disabled, separate empty
  stderr, zero exit, deterministic record count and SHA-256.
- Windows `rg --files` inventories normalize returned repository-relative
  paths to forward slashes before exact membership checks. A separator-only
  false zero is rejected and registered before any owner-dependent action.
- Named Flutter tests are copied from a no-match-safe literal projection of
  the freshly formatted exact test owner. A remembered prefix and any
  unclassified zero match are zero executable-test evidence.
- C30U device preflight captures raw `adb devices` output and its native exit
  before any PowerShell filtering. Only after exit zero may it require the one
  exact anchored OPPO ready row; a piped native status is inadmissible.
- PowerShell post-failure projections calculate conditional artifact states
  into explicit ticket-named scalars before object construction. Statement-form
  `if` is never placed directly in a property value.
- An authoritative Flutter JSON wrapper emits a bounded joined name and URL
  for every authored failed test before returning nonzero. Counts alone are
  insufficient to authorize a repair or an expected-pass-count change.
- Explanation-first YouTube account entry preserves the prior distinct-account
  and fail-closed avatar invariants. Diagnose exact C30J assertions before
  migrating any superseded first-tap expectation; never weaken authorization
  protections to fit a new dialog sequence.
- Source-shape assertions over large owners compare a bounded method region or
  a boolean `contains` result. A failed matcher never serializes the complete
  owner into expanded Flutter output.
- A signed-out-ready JourneySession fixture seeds completed setup/version in
  its exact in-memory store, calls `start()`, and asserts ready plus
  unauthenticated before testing account handoff. Booting or setup is never
  accepted as signed-out-ready.
- Reusing a JourneySession fixture also copies each store/model type's exact
  direct declaring import from the passing owner. `journey_session.dart` is
  never assumed to transitively expose fixture types.
- MVP scope selected-assessment validation enumerates the current root and
  nested owner names before reading a manifest path or digest. A remembered
  top-level projection and any null path are zero scope-binding evidence.
- A protected Social baseline rejection is diagnosed from its exact retained
  gate log. Genuine protected drift is never bypassed or resealed; an
  intentionally superseded checksum requires a separate C30U successor
  containment gate that replays every substantive protection.
- Protected candidate baselines keep the generic gate's empty `retainedApk`
  and `retainedApkSha256` compatibility fields even when the ticket's release
  artifact is an AAB. Missing fields are never bypassed with invented values.
- Final release-state reconciliation emits one bounded semicolon-delimited
  scalar record containing only the required machine state, seal comparison,
  OPPO state and build/upload/install counts. A structured projection that the
  host truncates is zero evidence and is registered before a bounded retry.
- A user-facing-copy qualification rejection is diagnosed from its exact
  immutable attempt log and named owner before any retry. A valid prohibited-
  copy invariant is never weakened, while a stale expectation requires a
  ticket-specific successor proof rather than an unrecorded bypass.
- Windows ripgrep owner lookups use explicit existing literal paths, or an
  existing directory plus `--glob`. A shell-style wildcard is never passed as
  a positional Windows filename, and a mixed-output nonzero lookup is not
  accepted as a complete inventory.
- Historical baseline paths are never reconstructed from memory. Use an
  already verified owner, or resolve an exact name with a bounded inventory
  and require one match before reading it; a guessed missing path invalidates
  the combined lookup.
- Protected-tree membership is proved with a no-match-safe exact relative-path
  query against the current and predecessor manifests before any reseal claim.
  Narrative scope descriptions are not file membership; zero exact matches
  require replaying the unchanged seal instead of rewriting it.
- An OPPO installer-source rejection is registered before another ADB read.
  Capture native exits immediately and project only the exact package manager
  installer fields; never mutate, reinstall or weaken the Play-predecessor
  invariant to make a qualification gate pass.
- A package-manager read returning ADB exit 255 is not repeated blindly. First
  capture `adb devices` and its native exit, require the exact OPPO state row,
  and request founder USB interaction when the state is not `device`; never
  mutate the installed app as a connectivity workaround.
- OPPO package-service subcommands are capability-checked by their native exit
  and bounded output. `Unknown command` is not non-Play evidence; use a
  supported exact-package installer listing and require the one literal
  `installer=com.android.vending` identity instead.
- Executable-owner searches stay within the exact script directories and do
  not include the full registry or quality archive. Prior incidents are read
  from already located bounded line regions; timeout 124 partial output is
  incomplete evidence.
- A source manifest is provisional until every count, membership and hash
  postcondition passes. Failed-attempt manifests are preserved byte-for-byte
  and never overwritten; future qualifiers promote an accepted canonical path
  only after validation rather than writing it before later assertions.
- Repeated Windows positional-wildcard mistakes are escalated: before every
  multi-path `rg` call, verify each positional path exists literally. Put all
  filename patterns behind `--glob`; a visible positional asterisk rejects the
  command before execution.
- Source-manifest compare mode uses exact byte length plus SHA-256 equality.
  Do not call `AsSpan()` as a byte-array instance method from PowerShell;
  exercise both OutputPath and ComparePath modes independently before final
  qualification cycles.
- Post-cycle JSON validation enumerates the exact current schema before reading
  a property. Validate named scalars separately; an opaque combined assertion
  is zero evidence. If registering the mistake changes a sealed memory owner,
  preserve the old cycle as superseded and run two fresh versioned cycles.
- Source-qualified `available_once` authority is not permission to call the
  AAB gate's build phase directly. Only the visible founder wrapper may collect
  hidden inputs, qualify transient configuration, invoke the build phase at the
  correct boundary and consume the one build authority.
- Versioning cycle JSON does not version attempt logs. Before each cycle,
  enumerate its exact full log set and require every path absent; use the first
  unused attempt number. Never reuse or overwrite a prior cycle's immutable
  log stem.
- Release-wrapper owner checks read only exact known existing paths. Never infer
  a build-script filename from convention. After final cycles, perform no
  exploratory search; launch the exact statically qualified founder wrapper
  directly.
- A founder build preflight rejection is not a consumed build. Prove zero count
  and available authority, diagnose only the named bounded assertion and its
  generated owner, and never retry hidden inputs until the preflight passes
  independently and any changed source has completed two fresh cycles.
- OPPO Chrome tester-link navigation separates focus, text entry, value
  verification, submission and destination verification into individually
  observed actions. A combined type-and-submit result is zero navigation
  evidence and must be registered before any corrected retry.
- Social/authentication owner searches use exact existing Windows positional
  paths and put Dart filename selection behind `--glob '*.dart'`. Partial
  output followed by an invalid positional wildcard is incomplete evidence.
- Regression identifiers and statuses are read from
  `config/codex-development-regression-registry.json`; the prevention-prose
  memory is not assumed to repeat every REG identifier inline. Its exact
  filename is resolved before any required read and is never reconstructed
  from remembered shorthand.
- OPPO install reconciliation never searches the full historical quality
  archive for a timestamp. Use the exact current package fields, the selected
  candidate state and an already located predecessor owner; timeout 124 or
  partial archive output is zero evidence and is never retried broadly.
- Authentication presentation and dispatch share one availability contract.
  A method without qualified live dependencies is visibly unavailable, has
  disabled semantics and cannot invoke a gateway; the presence of client code
  or a unit-test fake is not provider-readiness evidence.
- Android Google identity errors after account choice are not assumed to be
  user cancellation. Preserve structured failure truth, roll back partial
  Firebase identity when account bootstrap fails and require Play-signing plus
  live-provider readiness before a release success claim.
- Guest Feed read entry is proved separately from protected Social writes.
  Expected create, like, comment, share/repost, save and message authentication
  gates retain exact return continuity and are never mislabeled as a public-
  Feed failure.
- A historically ticket-scoped approved-UI gate is not widened for a new
  repair. The successor adds a separate containment gate that proves the old
  owner is unchanged, replays every substantive lock and adds only the new
  ticket's exact invariant.
- Multi-document status patches use independently read exact anchors for each
  target. A closing sentence from one quality document is never assumed to
  occur in another; atomic rejection is verified before bounded split retries.
- Full-manifest Flutter JSON audits use a non-killing process timeout and
  short wait yields for progress. A parent-shell timeout before the bounded
  counted summary is zero qualification evidence and is never reinterpreted.
- Flutter expected-pass deltas are bound to exact normalized membership of
  every changed test owner in the selected manifest. A remembered broader
  total plus newly authored tests is not a valid manifest-specific count, even
  when the native run has zero failures.
- Each cycle summary binds every named suite to a native execution in that
  exact cycle. Focused results are never copied from a prior cycle; they are
  either rerun with exit zero or explicitly recorded as not rerun.
- Chat capability audits resolve test owners with `rg --files` before content
  search. A positional Windows path containing `*` rejects the complete
  command even when other literal paths emitted partial matches.
- Optional dependency-symbol searches run separately and normalize ripgrep
  exit 1 as a valid no-match result. They never control the exit status of a
  combined command that also contains required source reads.
- Private attachment redaction is scoped to Storage object paths, generations,
  binding metadata and signing details. It does not erase the established
  participant-visible sender or current target-thread identity contract.
- Regression entries reference only evidence and gate files that already
  exist. A planned gate remains in its ticket until it has been created and
  passed; future paths are never registered as current evidence.
- TypeScript contract expansions update every structural fake in the same
  implementation wave. Runtime-narrowed union fields are pinned with explicit
  normalized result types before returning them across an interface boundary.
- A direct signed Cloud Storage URL necessarily serializes its object name.
  Private Chat uses an opaque UUID-only name with no user/thread/filename data,
  omits raw path/generation/binding fields and documents the short-lived URL.
- Strict TypeScript tests retain required map values in definite locals before
  corrupting fixtures. A `noUncheckedIndexedAccess` map read is never assigned
  to a required string without an explicit existence assertion.
- Repeated TypeScript parameter-list patches use a unique method-name anchor.
  Test-double tuple arity and index mapping are read and verified before a
  contract retry; a generic `requestDigest` anchor is insufficient.
- Heterogeneous tuples with adjacent `string` fields are corrected by replacing
  the full named tuple block, not by incremental string-slot hunks. Semantic
  position and method-assignment arity must be enumerated before retry.
- Source and source-test work use the regression gate's exact supported
  `implementation` phase. A resumed gate command never invents a semantic
  alias such as `source`; validate the script parameter contract first.
- Optional private constructor fields use initializing formals when linted.
  A nullable gateway that may implement a separate capability interface is
  resolved to one explicitly typed non-null capability owner before use; do
  not depend on implicit intersection-type promotion at the invocation.
- A failed multi-step session or widget journey projects busy, exact error and
  notice, pending-state identity, gateway request count and control hit-test
  visibility at the failing boundary before any correction. A shared symptom
  never substitutes for a proven common cause.
- A session never adopts a gateway-returned collection as mutable local state.
  Copy messages into a new growable list at the ownership boundary, and retain
  fixed-length response tests for every later local append journey.
- Historical gate labels are not script filenames. Resolve predecessor owners
  with a bounded `rg --files` inventory, require literal existing paths, then
  read them; no naming convention may substitute for path evidence.
- A successor static gate binds the predecessor owner's actual discriminant
  and rejection path. It never invents a field-name check when the established
  message-type contract already excludes the new variant.
- Independent optional inventories are normalized independently before any
  aggregation. `Promise.all` never owns raw ripgrep searches that may validly
  return exit 1; each leg emits an explicit match or no-match result first.
- When successive test-only tickets legitimately edit one shared test owner,
  each predecessor gate preserves its own intermediate hash in machine
  evidence but binds executable current bytes through the active successor or
  a preserved qualified-successor assessment. Lifecycle-safe ticket selection
  alone does not make an unconditional shared-file hash lifecycle-safe.
- A ticket used as a byte-bound selection manifest is not a mutable lifecycle
  mirror. Before changing any ticket status, inventory its literal hash
  bindings; readiness progression belongs in the dedicated machine state,
  aggregate and scoped status owners while the sealed ticket remains exact.
- A founder-input marker cannot mean both "inputs are available to the current
  wrapper" and "the one prompt/build boundary is already consumed." Keep it
  false through the wrapper's prebuild gate and persist it only atomically with
  post-preflight build-authority consumption; static order checks must span
  both owners and a behavioral test must prove the transition.
- A cycle command that changes working directory resolves every retained log
  to an absolute repository-contained path first. Relative artifact paths are
  never redirected after `Push-Location`; a redirection failure before native
  process start is zero analyzer evidence.
- Repository-relative searches run from the repository that owns every named
  path. Production and screenbook relative paths are never combined under one
  working directory; use separate searches or verified absolute paths.
- A reused persistent browser binding with no callable-surface details in the
  current context is inspected before navigation. Never guess a tab-open API;
  invoke only a method verified on that exact binding.
- An in-app-browser local-file URL policy block is never bypassed through raw
  browser commands or another control surface. Continue only with immutable-
  source/static verification and founder-controlled local review.
- Post-correction static audits separate source/hash checks from structural
  assertions. A host-level rejection of a monolithic inline command is zero
  evidence and no individual assertion result is inferred from it.
- C33I Windows static-audit checks run as serial single-process invocations.
  A concurrent shell-spawn rejection is zero evidence and is never retried in
  parallel.
- C33I HTML verification uses serial bounded `rg` exact-anchor checks and
  direct hashes. Do not retry host-rejected inline full-file substring/regex
  assertions; normalize expected no-match checks explicitly.
- C33I qualification and handoff owners are resolved with `rg --files` before
  content search. A partial match followed by a missing guessed path is zero
  evidence and is never reused.
- Post-`FINAL` status checks name exact files only. Never target the complete
  `apps/mobile/test` directory in a dirty evidence tree; resolve exact test
  owners with `rg --files` first.
- Founder-screenshot PowerShell inventories assign statement-form loop output
  to an explicit ticket-named array before formatting. A bare `foreach` before
  a pipe remains a parser failure even when the inventory is otherwise bounded.
- On Windows, never pass a wildcard as a positional `rg` path. Resolve script
  owners with `rg --files` first and search only verified exact paths; mixed
  matches plus an invalid-path error are zero evidence for that lookup.
- Dependency and optional-root searches resolve every manifest/path with
  `rg --files` before content search. Conventional root filenames are not
  assumed, and a missing path must not be conflated with a clean no-match.
- Do not bundle independent new ticket owners with historical prose appends
  whose byte context was not inspected. Create new files separately, inspect
  exact tails, then apply chronological corrections against verified anchors.
- A shrink-wrapped viewport such as `GridView` must never sit below
  `IntrinsicHeight`. Screen03 scroll fit uses non-intrinsic constraints and
  proves both the chooser and the smallest 140-percent-text viewport.
- Command paths are relative to the declared working directory. After entering
  `apps/mobile`, use `lib/...` and `test/...`; formatting and tests run as
  separate fail-fast steps.
- Flutter failure retries use compact reporting and bounded evidence. A
  truncated repeated render stack is failure evidence, never a full test run.
- JSON static gates bind nested properties from the exact parsed owner schema.
  Never move a known field to a plausible sibling object by inference; C33J
  founder decision is `acceptance.verification.founderDecision`.
- Privacy static assertions target the exact persistence schema, not a token
  across an entire runtime owner. C33J permits an opaque in-memory Firebase
  argument but forbids email-link or email-address fields in `JourneySnapshot`.
- Compact Flutter reporting does not bound application debug output. When an
  exact-file pass transcript is still truncated, replay the identical batch
  through a terminal-summary filter and preserve the native process exit code.
- A predecessor gate that byte-binds its historical ticket/release context is
  not an unconditional current semantic gate. Preserve its qualification,
  run its focused Flutter matrix, and compose it only through the active gate.
- External authentication returns prove both cold-start and already-running
  delivery. A `defaultRouteName` parser alone is incomplete; an active-process
  route-information handoff must reuse the same validator and state owner.
- Regression entries list only repository paths that already exist. Planned
  tests and checkers remain in ticket scope until created, then are added to
  registry gates after validation.
- Do not infer that a production binding callback has a same-named widget-test
  helper. Deep-link tests bind only a public injection surface verified in the
  current official Flutter API for the pinned SDK.
- An authentication return intent is transient and may be consumed after the
  router reaches it. Post-navigation tests assert the exact destination through
  query-selected rendered semantics, then separately assert one-shot intent
  consumption; `readyRoute()` is not a current-router-location oracle.
- Foreground authentication return is not qualified by successful credential
  completion alone. The exact query-selected destination must exist in the
  rendered router tree after the callback; an absent owner is a blocking
  navigation finding, not an assertion to remove.
- When a successor strengthens a protected runtime invariant, update every
  predecessor static composition anchor before replay. Run independently
  countable gates separately and count only their observed exit-zero results.
- Windows `rg --files` output may use backslashes. File-filter expressions use
  `[\\/]` when portability is required; known affected files are better
  validated with literal paths before execution.
- Machine-state enum fields use only values explicitly accepted by their
  current checker. Preserve richer founder wording in adjacent evidence fields;
  do not invent a descriptive enum value.
- If a browser semantic action reports no effect or coordinate translation
  failure, do not repeat it blindly. Inspect fresh visible DOM, retarget the
  exact node, verify local form state, then submit and count only authoritative
  post-submit readback.
- A submitted external configuration form is not a successful write. Count it
  only after authoritative post-submit readback; a visible rejection preserves
  the prior count and triggers safe prerequisite diagnosis before retry.
- Do not infer a local CLI command group from a REST resource name. Prove the
  installed command surface first, and never obtain or print OAuth tokens to
  bypass an unavailable command.
- If two distinct writes to the same external console are rejected while
  read-only access works, stop write retries in that unchanged session. Treat
  authentication/IAM as the shared blocker, retain zero action counts and
  continue only safe source preflight or sanitized readback.
- A capability present in current official CLI documentation may be absent
  from the installed CLI. A failed dry-run closes that local target: do not
  retry, update tooling or use credential/token workarounds without authority.
- Firebase inline-editor actions that have already shown coordinate-translation
  failures use fresh visible-DOM node targeting for the rest of that dialog.
  Keep authoritative provider state separate from dialog-control failures.
- A successful single-AAB transition advances every detailed and aggregate
  count and authority mirror before postbuild qualification. The wrapper gate
  asserts all mirrors, and the exact successor seals an interrupted-postbuild
  recovery owner before build. Any mismatch rejects that candidate; it is not
  manually promoted or rebuilt under consumed authority.
- Postbuild inspection names literal verified wrapper, gate, state, manifest
  and evidence files. Never recurse through the retained artifact tree to find
  an authority transition; a timeout is zero evidence and is registered before
  a narrower attempt.
- Founder-input launchers erase every transient file, environment value and
  secure string before retaining a bounded terminal result. An automatically
  closed window is never interpreted as full build or release success.
- A mutation call whose output is truncated is an unknown result, never a
  pass. Read back every exact target before retry, register the occurrence,
  split the retry into bounded patches, and verify manifest hashes and selected
  state before invoking a gate.
- PowerShell verification projections are assigned to one ticket-named object
  before serialization. A table followed by `null` is malformed structured
  evidence even when its displayed property values are otherwise readable.
- Multi-location launcher edits use freshly read, unique local owner tokens for
  each hunk. A failed patch-context verification is zero writes and is
  registered before a smaller anchored retry.
- Dual-host parser evidence reports the exact nonzero expected file count. Do
  not pass arrays after a PowerShell `-Command` string as though it were a
  script-file parameter boundary; build the literal array inside each host.
- Every qualified child prevention gate is audited for successor replay before
  parent sealing. A gate may replay only when current and selected tickets
  agree and the exact prior qualified manifest hash, state and evidence remain
  pinned; active-ticket-only scope calls are blocking findings.
- Generated manifest copies normalize exactly one terminal newline and still
  require immediate SHA-256 equality. A one-byte trailing-line mismatch blocks
  ticket selection even when semantic JSON content is identical.
- A repair spanning function, lifecycle and reporting regions uses separate
  freshly anchored patches. One remembered distant status line must not make a
  complete prevention-gate repair unverifiable.
- Cycle-command inventories resolve every gate with `rg --files` before
  reading parameters. A ticket ID never implies a same-named checker, and a
  failed guessed-path lookup supersedes any source seal whose registry it
  subsequently changes.
- Parent-replay repairs never encode only one historical parent when the
  prevention is required by future successors. Use exact generic successor
  binding to current/selected identity plus qualified predecessor hashes,
  states and evidence, with negative fixtures.
- A truncated read-only audit result is unknown evidence. Register it before
  retry, supersede any source seal whose registry generation it changes, and
  replace broad context projection with exact line-number discovery followed
  by one bounded literal line slice.
- Validate post-launch reporting expressions before crossing an external
  process boundary. A reporting error after `Start-Process` makes launch state
  unknown; register, stop the exact sanitized launcher if live, prove counts
  and cleanup, then reseal before any retry.
- A command-line process selector always excludes its own `$PID` before any
  mutation. A literal needle appears in the diagnostic invocation itself; a
  self-terminated cleanup is zero evidence and requires a separate proof run.
- Browser release work never enumerates or emits raw open-tab objects. Open one
  fresh known allowlisted Play route and return only query-free host/path plus
  non-private release fields; history, unrelated metadata, query/fragment,
  account/tester, private-link, cookie, storage and session data remain unread.
- A candidate aggregate reset uses exact independently read and parsed hunks.
  One remembered combined state/aggregate layout is not sufficient evidence.
- On Windows, `rg` filename selection uses an exact directory with `--glob`;
  a shell wildcard embedded in the path is a rejected partial inventory.
- Fixture projections use an exact path array piped through `ForEach-Object`.
  Never append a formatter pipeline to a statement-level `foreach` block.
- After that empty-pipe class recurs, keep scalar reconciliation separate from
  fixture projection, require successful parser output, and count neither
  rejected command as inventory evidence.
- Static documentation gates bind semantic tokens with whitespace-tolerant
  assertions. Ordinary Markdown line wrapping must not create a false release
  rejection, while removal or alteration of any required token still fails.
- A gate invocation that may yield retains the complete execution result,
  including session id and exit metadata. Empty visible output without that
  metadata is unknown evidence; prove exact process absence before retry.
- Candidate-owned prerequisite messages name the exact final registry
  generation and are asserted by the candidate gate. A stale human-readable
  registry literal is corrected before it can emit a false success record.
- Every preprompt and postinput fixture projects the exact current candidate
  evidence paths from real state before matrix execution. Candidate-name
  substitution does not prove a date-bearing cloned path exists.
- Fixture reference audits distinguish durable evidence from the one exact
  founder-created release `google-services.json` transient, whose preprompt
  absence is required. No diagnostic creates or inspects that file.
- Long-path manifest exclusion audits print each target and match count as
  labeled scalar fields. Clipped table columns are unknown evidence and never
  establish that mutable candidate owners are excluded.
- In a PowerShell `switch` nested inside a `foreach`, an unlabeled `continue`
  does not establish that the outer event loop was skipped. A non-object JSON
  classification uses an explicit outer-loop label, and a focused executable
  case proves blank, non-JSON and JSON-null inputs never reach event access.
- Post-rejection source diagnosis starts with scalar match counts and bounded
  line numbers, then reads narrow explicit slices. Broad source projection,
  combined huge-status reconstruction or stale remembered filenames are
  unknown evidence and are registered before a bounded retry.
- Windows path resolution compares exact filenames or accepts both separators.
  Git porcelain's literal `??` prefix is tested with `StartsWith`, never a
  PowerShell wildcard pattern, and status category sums must equal the total.
- State/aggregate parity compares named shared contract fields. Deliberate
  owner-shape differences are not byte-equivalence defects; action counts,
  machine state and release authorities are compared independently.
- Two required independent source cycles keep real detailed and aggregate
  state at `0/2` for both invocations. Never persist an intermediate `1/2`;
  verify both retained summaries first, then atomically persist `2/2` and both
  evidence paths before dual-host replay or founder-input authority.
- Rejected aggregate evidence must be checked at every redundant mirror. A
  nested candidate block cannot inherit predecessor build counts or artifact
  hashes when authoritative action counts are zero; successors initialize
  count and artifact fields explicitly rather than trusting a cloned reset.
- Plan-tool output is advisory. A truncated or empty orchestration projection
  cannot authorize a candidate or lifecycle step; reconstruct decisions from
  the durable ticket, state, aggregate, runbook and retained evidence.
- A qualified focused gate is not assumed successor-replayable. Audit its
  current-ticket scope binding before selection; preserve the qualified owner
  and add only one thin current-successor replay checker when exact immutable
  behavior must remain enforced under a new selected ticket.
- Candidate browser evidence preserves its actual qualification subject and
  generation. Mechanical candidate renaming cannot turn an immutable prior
  workflow qualification into a new live browser action; successors label
  reused provenance and zero new Play writes explicitly.
- Browser/document composition markers use whitespace-tolerant semantic
  assertions. Ordinary Markdown wrapping cannot turn a truthful no-action or
  provenance statement into a false release rejection.
- Retained-process polling uses a simple valid tool call with the complete
  session id. A JavaScript wrapper parse error is no process evidence, and any
  intervening registry registration supersedes a pre-seal gate invocation.
- After a retained-session poll wrapper parse failure recurs, subsequent polls
  use one awaited `write_stdin` call and one plain output projection only; no
  conditional or template-literal projection is included.

This memory does not authorize a ticket, build, install or protected-runtime
change. It strengthens the gates of otherwise authorized work.

## C34L FIX3 journey-adapter metadata-read prevention — 18 August 2026

- REG2911 preserves a read-only parser failure caused by piping directly from
  a statement-level PowerShell `foreach` block into `Format-Table`. The
  command body did not execute and no source, evidence, external, browser,
  device, private or release state changed.
- Materialize loop results before any pipeline, or prefer independent scalar
  owner reads. Stop at the first parser failure, register it, replay this
  memory, and accept only warning-free bounded output before implementation.
## C34H r60.72 postinstall rejection and successor prevention — 17 August 2026

- REG2704 preserves the sanitized transient-check PowerShell parse rejection
  and requires separate loop collection and serialization.
- REG2705 preserves the fail-closed preupload call made before explicit
  upload-authority projection.
- REG2706 requires Play's visible Upload control and file-input shape to be
  inspected before one-time authority is consumed.
- REG2707 prohibits shell-style wildcard path operands in Windows ripgrep
  calls and requires the exact state-owned gate path.
- REG2708 requires a fresh exact `CPH2375` mirror re-selection after every
  founder/device takeover.
- REG2709 rejects C34H because a YouTube-provider tap opened an Android account
  chooser containing private identifiers. No account was selected and the
  founder closed the chooser. All account-capable provider taps are now
  founder-only boundaries.
- C34H is permanently retained at `1/1/1/0`. Its AAB, Internal Testing
  release and installed OPPO build are historical evidence only and cannot be
  repaired, retried, promoted or claimed accepted.

## Post-C34H successor-selection tooling prevention — 17 August 2026

- REG2710 preserves a read-only pre-ticket wrapper rejected because a pipeline
  followed a statement-level `foreach`. It returned zero requested document
  content and changed no repository or external state.
- Required pre-ticket documents are now read directly by literal path in
  bounded calls. Loop collection and serialization are never composed as one
  PowerShell pipeline.

## C34I dual-host test orchestration prevention — 17 August 2026

- REG2711 preserves a JavaScript wrapper rejected before any terminal command
  because it used a PowerShell-style string method. It is zero parser or gate
  evidence and changed no repository or external state.
- Fixed repository paths are passed directly to four plain parser/gate
  commands; no JavaScript path-method transformation is used.

## C34I mechanical owner generation prevention — 17 August 2026

- REG2712 preserves the pre-execution parser rejection caused by uppercase and
  lowercase variants in one case-insensitive PowerShell hashtable. It created
  zero candidate owners and changed no external state.
- Case-sensitive lowercase substitution is a separate explicit
  `String.Replace` after the ordered map; the generator parses before its one
  retained execution.

## C34I generated-owner semantic readback prevention — 17 August 2026

- REG2713 preserves a pre-cycle readback finding: a bare predecessor registry
  count and a nonexistent mechanically renamed replay path remained after
  generation. No test or external action started.
- Generated owners are audited for all registry literals, predecessor tokens
  and referenced-file existence. C34I cycles invoke the selected shared
  device-actor policy self-test, not a fabricated predecessor replay path.

## C34I mutable lifecycle-state manifest prevention — 17 August 2026

- REG2714 preserves the unbound registry-2684 draft that included mutable
  candidate state and aggregate files. No cycle or external action started.
- Immutable candidate owners remain manifested. The two mutable lifecycle
  states are explicitly excluded from byte hashing and are instead enforced by
  the immutable candidate gate across registry, policy, count, authority,
  privacy and phase-transition parity.

## C34I postbuild lifecycle-mirror rejection — 17 August 2026

- REG2715 preserves the one authorized C34I AAB at `1/0/0/0`. Compilation,
  artifact sealing and provenance completed, but the wrapper consumed the
  aggregate build authority without consuming the matching detailed build
  authority. The postbuild parity gate failed closed and no Play or OPPO action
  occurred.
- C34I is permanently non-reusable and cannot be rebuilt, repaired, uploaded or
  promoted. A successor must test the executable success-transition function,
  not merely its source tokens, against positive and fail-closed detailed plus
  aggregate fixtures in PowerShell 7 and Windows PowerShell.
- The fixture matrix covers every mirrored phase field before any real build:
  machine state, authorization, release authority, action count, disposition,
  artifact identity, artifact reusability, upload/activation counts, in-place
  Play update count, device-acceptance count, privacy flags and rejection.

## C34J MVP-state bounded patch prevention — 17 August 2026

- REG2716 preserves a zero-write combined patch rejection caused by remembered
  context in a long selected-ticket assessment. No ticket, state, build or
  external action was changed by the rejected patch.
- Each MVP-state target is read and patched through one unique bounded anchor;
  full JSON parsing and the MVP scope gate are mandatory after all sections.
- REG2717 preserves a second zero-write patch rejection caused by retyping the
  prior ticket hash incorrectly. Hashes are projected from parsed live JSON and
  used without manual transcription.
- REG2718 preserves the pre-gate readback of a transposed hash in the newly
  inserted prior-C34I assessment. The exact on-disk hash is corrected and both
  selected and prior assessment hashes are verified before the MVP gate.
- REG2719 preserves a zero-fixture dual-host parser wrapper failure caused by
  an invalid nested `-Command` positional path. Each host executes the checker
  directly with `-File`; the checker itself parses the transition owner first.

## C34J mechanical generator case-pair recurrence — 17 August 2026

- REG2720 records a recurrence of REG2712: uppercase and lowercase phrase
  variants were again placed in one case-insensitive PowerShell hashtable. The
  parser stopped before any candidate owner was created.
- The prevention applies to every case-distinct replacement pair, not only a
  candidate token: the map keeps one case variant and lowercase replacements
  run as explicit `String.Replace` calls after the map.
- REG2721 preserves the subsequent pre-cycle semantic readback: hyphenated
  version fragments and a registry literal were not covered by lexical
  replacement. Every representation and referenced path is audited from live
  owners before prerequisite-only execution.

## C34P 20 August production-auth continuation prevention

- REG2994 repeats the prohibited grouped reconstruction class. Workspace and
  repository instructions, handoff checkpoint, branch, HEAD and dirty digest
  are independent bounded results; full status and raw handoff output are
  never emitted.
- REG2995 repeats the disposed-process exit-code loss. Copy native `ExitCode`
  after `WaitForExit()` and before disposal, then require all five non-emitting
  digest fields to be present.
- REG2996 rejects a 46-entry narrative registry-tail projection that truncated.
  Tail work resolves the exact last line and emits only measured bounded
  groups; truncated JSON is zero registry evidence.
- REG2997 proves a recorded coordination claim can contain a missing owner.
  Every recorded owner must exist as a repository leaf, and the gate must have
  a negative missing-owner fixture before the corrected claim qualifies.
- REG2998 binds backend App Check replay consumption to Flutter limited-use
  token acquisition. A normal cached `getToken()` result cannot call a custom
  endpoint that verifies with `consume: true`; source composition and focused
  tests must retain the limited-use API plus backend replay rejection.
- REG2999 rejects unary `-not` applied directly to a parameterized cmdlet in a
  dense readback condition. Resolve `Test-Path` into an explicit boolean scalar
  first, then negate only that scalar before projection.
- REG3000 rejects a green X contract test that approved the ticket-forbidden
  `offline.access` scope. The pure contract, production adapter, backend and
  gates all enforce exactly `tweet.read users.read` with no refresh lifecycle.
- REG3001 rejects successor test totals inferred from a predecessor narrative.
  Freeze every current suite path and accept only the bounded executable count;
  the current all-auth affected manifest is 16 literal suites and 158 tests.
- REG3002 records Cursor's reported full-status-output incident. Cursor and
  Codex use only independent branch/HEAD scalars, the five-field non-emitting
  dirty digest and literal claim-scoped status; the full inventory is never
  repeated or retained.
- REG3003 repeats the PowerShell interpolated-colon parser class in a read-only
  module inventory. Error messages use the format operator; `$root:` and every
  equivalent variable-colon spelling are forbidden before command execution.
- REG3004 rejects a long reconstructed MVP selected-assessment replacement.
  Successor scope changes patch one unique scalar or one small exact array at a
  time and parse/project each accepted hunk before the next.
- REG3005 rejects the Cursor B0 staged/worktree/conflict wrapper whose uncaptured
  stderr emitted an unbounded LF-to-CRLF filename warning stream. Do not retry;
  use separate in-memory streams and bounded counts/hashes or the existing
  porcelain aggregate.
- REG3006 requires provider-readiness pending state to support lawful
  incremental console-write counts while every deployment/private/email/SMS/
  build/Play/OPPO/production/funds count remains held.
- REG3007 rejects an empty evidence-readback projection. Verify one literal
  owner with minimal existence, line-count and SHA-256 scalars after refreshed
  gates; no empty result is accepted.
- REG3008 requires the complete memory and coordination replay after every
  power loss before even an incident evidence write. Partial reconstruction is
  not write authority.
- REG3009 rejects Meta's literal placeholder-based Windows key-hash example in
  PowerShell. Never retry it: export one certificate to a unique temporary
  file, hash the DER bytes through .NET, copy only to the founder clipboard,
  delete the temporary file in `finally`, and never emit the hash.
- REG3010 rejects assuming `keytool` is on PATH. Resolve one exact configured
  JDK executable through bounded path checks before invocation, keep the
  fingerprint clipboard-only, and retain `finally` cleanup.
- REG3011 requires naming the credential domain before every password-bearing
  command. Never use an online-account password for a local keystore; stop and
  register a rejected prompt before retry, and keep fingerprints founder-only.
- REG3012 rejects cumulative terminal history as current-attempt evidence. Use
  a fresh process or unique attempt marker and report only one literal bounded
  success/failure class, never the password, fingerprint, path or clipboard.
- REG3013 rejects splitting PowerShell `try`/`catch`/`finally` across terminal
  submissions. Keep one parser unit, clean only resolved uniquely prefixed
  temporary certificate files, and close the interactive process afterward.
- REG3014 rejects combining enumeration, confinement and deletion in one dense
  nested shell command. Use only the interactive session's already-resolved
  exact literal path, dispose objects, clear variables and close the terminal.
- REG3015 rejects short patches against repeated provider-state field names.
  Anchor every hunk to the literal provider object, parse and project the two
  affected subtrees, then rerun both FIX5 host gates.
- REG3016 rejects `Set-Clipboard -Value ""` in Windows PowerShell 5.1 because
  the host normalizes it to null. Overwrite with one harmless space and close
  the terminal instead.
- REG3017 rejects casting a multi-case test table as one tuple. Declare one
  explicit array of readonly `[Buffer, string]` tuples before typecheck and
  focused/full backend replay.
- REG3018 proves the secure Email Link continuation `/app` is live 404 while
  `assetlinks.json` is 200. Add and locally test a minimal fallback, keep
  hosting deployment separately held, then require authorized live 200 before
  qualifying the release define or any real-email OPPO journey.
- REG3019 rejects an Identity Toolkit Admin PATCH made with user credentials
  but no quota-project header. Bind `X-Goog-User-Project` to the exact Dev
  project while retaining the one-field mask and sanitized response.
- REG3020 rejects positional wildcard paths in Windows `rg`. Use a literal
  directory plus `-g '*test.ts'`, then run focused and full backend replay
  before any Firestore TTL write.
- REG3021 rejects interrupting accepted synchronous Firestore TTL writes. Do
  not rerun them; use `--async` for future writes and poll only bounded
  `ttlConfig.state` values until both exact groups are `ACTIVE`.
- REG3022 rejects a grouped local `gcloud` predefined-role probe whose six
  suppressed describes all returned nonzero. Validate roles individually in
  the authenticated Dev Cloud Shell before any IAM creation or binding.
- REG3023 requires immediate rotation when a provider secret field is captured
  revealed or selected. Copy the rotated value only into a pre-waiting hidden
  prompt, re-hide it, and return only the version marker.
- REG3024 rejects retrying a disappeared visible deployment process. Read back
  only function existence, then open a prompt-only `-NoExit` shell, confirm it
  visibly, and have the founder type the deployment command there.
- REG3025 rejects deploying before local Firebase credential freshness is
  verified. Reauthenticate interactively in the same visible shell, never use
  `login:ci`, recheck function absence, replay gates and retry only the exact
  function deployment.
- REG3026 rejects returning full interactive reauthentication transcripts.
  Never return private login URLs, states, identifiers, codes or tokens; report
  only the literal sanitized success marker.
- REG3027 rejects an unqualified Firebase function filter when `firebase.json`
  declares the `provider` codebase. Validate CLI syntax, then deploy only the
  exact codebase-qualified function.
- REG3028 records the private reauthentication transcript recurrence. Never
  copy terminal history; return only the current command's sanitized outcome.
- REG3029 records a partial deployment: parameters saved and function create
  succeeded, but the command ended in error. Do not retry or invoke before
  final-error classification and authoritative runtime/IAM readback.
- REG3030 records the second private reauthentication-history recurrence.
  Return only current-command markers or a safely cropped tail.
- REG3031 rejects retrying a public Run Invoker binding under effective
  domain-restricted sharing. Classify only the constraint type, then require an
  explicit founder decision before any policy exception or proxy write.
- REG3032 rejects checking the service-scoped invoker-disable update through a
  nonexistent top-level JSON field. Read the documented annotation/field and
  prove reachability only through status-code application rejection tests.
- REG3033 rejects pasting an Instagram deauthorization URL into the adjacent
  webhook field. Webhook URL/token stay blank; only the Step 4 Business login
  settings modal receives OAuth, deauthorization and deletion URLs.
- REG3034 rejects adding an optional App domain to a native-only Facebook app
  without a web platform. Remove the domain instead of expanding platform
  scope; save only privacy, terms and signed deletion callback values.
- REG3035 rejects returning the Meta Android platform section without redacting
  key-hash and Install Referrer material. Crop above it, keep automatic
  purchase/subscription/referrer features disabled, and rotate or document
  non-use before review.
- REG3036 preserves Cursor B1 but rejects B2's JavaScript-template/PowerShell
  backtick-tab composition before shell execution. Retry only with direct
  argument arrays, ordinary literals or a separate script and no backticks.
- REG3037 preserves B1 when a tracked owner matches a broad secret-path class.
  Primary classifies the exact Git owner privately and permits only a literal
  hash-bound sanitized allowlist or permanent exclusion before retry.
- REG3038 rejects assuming a singleton PowerShell JSON projection is an array.
  Normalize object-or-array output, keep paths private and emit only sanitized
  metadata until classification passes.
- REG3039 rejects a repository process census that includes its own diagnostic
  PID. Exclude the current process before matching and emit only bounded writer
  and source counts.
- REG3040 rejects serializing the registry's top-level object as an alleged
  tail entry. Project only `registry.entries` and emit bounded scalar evidence.
- REG3041 rejects assuming an obsolete shortened MVP gate filename. Locate the
  exact repository-owned `-RequireExecutionAuthorized` gate before invocation.
- REG3042 rejects grouping an assumed broker filename with verified runtime
  owners. Resolve the tracked broker path first, then search only literal
  existing paths.
- REG3043 rejects semantic filename-only discovery for a generically exported
  broker. Enumerate the bounded source directory before content matching.
- REG3044 rejects bare `true` in a PowerShell output object. Use `$true` or a
  bounded scalar marker and typecheck the final expression before the census.
- REG3045 rejects retrying or bypassing a rate-limited official Meta docs
  fetch. Retain existing console evidence and wait for normal availability.
- REG3046 rejects compressing parser-sensitive PowerShell loops in the frozen
  dirty-digest wrapper. Reuse the proven expanded wrapper verbatim.
- REG3047 rejects qualifying a preserved Cursor reconstruction after its
  registry pin moved. Incrementally refresh changed owners, regenerate the
  complete manifest and freeze primary registry writers through B3.
- REG3048 rejects full File Explorer Home accessibility capture for a scoped
  keystore search. Use bounded filename-only folder search and emit no paths or
  unrelated Recent/account metadata.
- REG3049 rejects pasting `finally` separately after a successful Firebase
  runtime load. Use standalone cleanup and one-invocation founder paste blocks.
- REG3050 rejects applying the retained C34L final-candidate gate to a
  non-release Play-signing bootstrap AAB. Replay C34L only for the later final
  auth candidate after Play signing registration.
- REG3051 rejects grouping a complete test/golden tree and guessed paths into
  an auth owner inventory. Filter verified roots independently and emit only
  bounded authentication owners.
- REG3052 rejects broad cross-root callback searches and positional Windows
  wildcard paths. Read exact callback-owner slices only.
- REG3053 rejects using a remembered upload-keystore environment name. Derive
  the canonical contract from current Gradle/wrappers; the path variable is
  `MOOLSOCIAL_UPLOAD_STORE_FILE`.
- REG3054 rejects bundling independent test owners behind an unverified patch
  anchor. Read exact context and patch each test file separately.
- REG3055 rejects dropping a yielded analyzer session handle. Retain
  `session_id` and poll the exact process to terminal completion.
- REG3056 rejects parent-only ticket assertions in a shared auth gate. Accept
  only the parent or explicit authorized descendants and retain unrelated-ticket
  negative coverage.
- REG3057 rejects coupling a shared auth contract gate to the original
  source-only authority vector. Validate the selected authorized descendant and
  preserve secret/private/external/device prohibitions.
- REG3058 rejects a gate output that claims unchecked action history. Shared
  auth gates report selected external authority, not `externalWrites=0`.
- REG3059 rejects parent-only MVP selection in the FIX1A gate. Permit only the
  parent or explicit FIX5 descendant and retain all child/source assertions.
- REG3060 rejects combining FIX7 creation and independent JSON/PowerShell
  owners behind a malformed file-boundary hunk. Patch each owner separately.
- REG3061 rejects using PowerShell's reserved `$PID` for an OPPO app-process
  marker. Use a task-specific variable and emit only the bounded boolean.
- REG3062 rejects assuming copied Play certificate text contains only 64 hex
  characters. Extract one strict SHA-256 token locally and emit no value.
- REG3063 rejects accepting an interleaved keytool prompt/marker transcript as
  password-strength evidence. Finish prompts first, then emit the marker.
- REG3064 records one accidentally submitted Play upload-key reset. Do not
  cancel or duplicate a correct pending request; wait for Play's outcome.
- REG3065 rejects immediate-create for a timezone-anchored Codex reminder. Use
  suggested-create with the exact DTSTART and verify the returned automation.
- REG3066 rejects priming a fingerprint clipboard before browser navigation.
  Recopy immediately before paste and save only after SHA-type recognition.
- REG3067 rejects launching a combined automated secret-prompt window. Use a
  value-free repository script invoked manually in the founder's open shell.
- REG3068 rejects resolving a repository-root helper from a mobile-package
  working directory. Use the absolute helper path before package-local tests.
- REG3069 rejects inferring raw policy patch context from a parsed owner
  projection. Read the exact bounded policy lines before patching.
- REG3070 rejects retrying a context failure without first inspecting the
  literal punctuation. Reproduce the live leading-comma tail exactly.
- REG3071 rejects running coordination with a claimed owner that does not yet
  exist. Complete the bounded owner creation before the next gate replay.
- REG3072 rejects changing the selected ticket without refreshing its pinned
  MVP manifest hash and exact execution scope before a build gate.
- REG3073 rejects passing a `string[]` runtime-define allowlist through nested
  `pwsh -File`. Invoke the gate in-process so the array remains intact.
- REG3074 rejects configuring Android `resValue` entries while custom resource
  values are disabled. Enable `buildFeatures.resValues` before release Gradle.
- REG3075 rejects an ignored `GeneratedPluginRegistrant.java` inside the
  Android main source set. Preserve it, remove it from compilation and gate its
  absence before release builds.
- REG3076 rejects moving an ignored compiler input that is also historical
  regression evidence. Preserve its path and exclude it through source sets.
- REG3077 rejects using `java.exclude` on AGP 9's Android source-set receiver.
  Prove the Java root inventory and use its supported `setSrcDirs` contract.
- REG3078 rejects attempting package signing before the founder-held store and
  key passwords are jointly validated. Re-prompt locally and validate in Java
  without command-line secret arguments.
- REG3079 records an optional installed-APK signer diagnostic blocked before
  execution. Do not retry when existing signing evidence proves the boundary.
- REG3080 rejects assuming a predecessor remains installed at action time.
  Re-read package presence and skip unneeded uninstall authority when absent.
- REG3081 rejects inferring package absence from raw ADB record count. Filter
  the exact normalized package line before the uninstall branch.
- REG3082 rejects combining creation and correction of two incident owners in
  one patch. Patch and read back each owner independently.
- REG3083 rejects adding a live device-review profile without updating the
  startup runtime-mode allowlist. Require its exact signed sideload facts.
- REG3084 rejects accepting a test cycle whose output truncates before the
  terminal result. Capture verbose output and emit a bounded exit/count seal.
- REG3085 rejects awaiting platform bootstrap before any Flutter-owned frame.
  Render a named frame first, bound each stage and seal real-device cold start.
- REG3086 rejects combining distant bootstrap hunks without exact final-range
  context. Patch and read back each startup section independently.
- REG3087 rejects retaining an execution pin after registry movement. Replay
  regression, coordination and MVP gates before any next mutation or test.
- REG3088 rejects a visible startup frame whose required semantics label is
  merged away. Use an explicit semantic container and test both representations.
- REG3089 rejects promoting source/widget startup proof without an installed
  cold-start receipt and sanitized stage identifier. Block successor builds.
- REG3090 rejects replaying coordination while a claimed device receipt is
  still missing. Create the bounded receipt immediately after its captures.
- REG3091 rejects claiming future generated screenshots before capture. Use
  temporary paths, then register only completed immutable evidence.
- REG3092 rejects an APK missing the production plugin registrant and Firebase
  Core class. Require both in source and dex while forbidding integration_test.
- REG3093 rejects inferring execution order from a helper definition's literal
  `runApp`. Gate the precheck and bootstrap call sites before Firebase instead.
- REG3094 rejects manually editing a Flutter-generated registrant. Apply a
  release-variant sanitizer and verify production/test plugin dex membership.
- REG3095 records a full-suite aggregate with 247 golden failures. Classify one
  representative shared cause before any source or baseline mutation.
- REG3096 rejects count evidence parsed with the wrong Node reporter syntax.
  Capture a bounded raw tail once, then parse the active exact summary form.
- REG3097 records Android lintRelease at 6 errors/2 warnings, including missing
  FacebookActivity. Fix all items without baselining before any successor APK.
- REG3098 rejects inferring a new Android owner position from absent policy
  context. Read the exact owner range before inserting the resource claim.
- REG3099 rejects any source patch immediately after registry movement. The
  next action must be the new regression/coordination/MVP gate replay.
- REG3100 rejects isolating YouTube by forbidding all MoolSocial schemes in
  MainActivity. Forbid only YouTube host/path and preserve X/Instagram returns.
- REG3101 rejects raw segment indexing for provider return URLs. Parse and
  assert scheme, authority, path and exact query independently.
- REG3102 rejects Cursor manifest reads that emit entries until output truncates.
  Emit only in-memory count/bytes/SHA/stderr/exit aggregates.
- REG3103 rejects adding audit assertions to a checksum-locked UI test. Restore
  it exactly and use a separately claimed successor audit owner.
- REG3104 rejects asserting durable escaping in Flutter-managed local.properties.
  Normalize it immediately before lint and gate the Gradle task contract.
- REG3105 rejects assuming an isolated worktree's immediate parent is the
  authorized workspace root. Mirror the authoritative workspace `AGENTS.md`
  at the exact worktree-parent path with byte/hash equality and qualify that
  mandatory-read resolution before dispatching or resuming the worktree.
- REG3106 rejects admitting a partial isolated-worktree evidence refresh from
  a pre-copy projection. Reconcile every current registry evidence owner with
  source/target length and SHA-256 equality and require zero missing paths
  before replaying the worktree's memory or coordination gates.
- REG3107 rejects copying the global active-claim set unchanged into an
  isolated baseline that intentionally excludes Desktop source changes. Use a
  primary-created worktree-scoped policy projection with the current registry
  binding and Cursor's exact report owner only; never copy Desktop auth/source
  owners merely to satisfy the isolated coordination gate.
- REG3108 rejects direct Gradle lint output as final evidence when the task
  stream truncates before terminal completion. Capture stdout/stderr in
  memory, retain the native exit immediately and emit only bounded lint/report
  counts plus report length and SHA-256.
- REG3109 rejects dispatching an isolated audit after reconciling only registry
  evidence closure. Materialize every exact mandatory-read owner required by
  that audit, including its current ticket, verify byte/hash equality and issue
  the literal incident path plus refreshed binding before retry.
- REG3110 rejects guessing a Hosting root for FIX7 status-page discovery.
  Resolve the current web owner from `firebase.json` or a bounded file
  inventory, search only literal existing paths and isolate expected absence
  with explicit no-match handling.
- REG3111 rejects a public deletion SLA that differs from the founder-approved
  FIX7 machine policy. Bind the public page and tests to the thirty-day maximum
  and expose only confirmation-scoped pending/completed/failed state.
- REG3112 records the REG3107 Cursor recurrence. Keep that isolated audit
  stopped for this phase; do not spend Desktop execution time on another local
  replay until a scoped policy and branch-safe gate are separately designed.
- REG3113 rejects projecting `.Path` from `Select-String` matches created from
  an in-memory filename stream. Use `-LiteralPath` per resolved file or bounded
  `rg` against literal roots whenever matched source paths are required.
- REG3114 rejects coupling distant FIX7 owner-claim insertions to remembered
  policy context. Reread each exact local neighbor, patch one bounded claim
  group, parse it and never treat atomic rejection as partial authority.
- REG3115 rejects claiming a shared backend runtime owner before projecting
  its active claimant map. Explicitly release an inactive claimant, require
  one canonical task and replay coordination before mutating that owner.
- REG3116 rejects assigning explicit `undefined` to exact-optional fields in a
  strict TypeScript test store. Structurally omit cleared fields through
  destructuring and rerun typecheck before compiled tests.
- REG3117 rejects guessing `activeTasks` from the human phrase active tasks.
  Project the exact `activeClaims` root, filter its `task` field and require one
  exclusive owner before a subagent gate or audit.
- REG3118 rejects projecting registry entries through an invented wrapper.
  PowerShell reads `$j.entries`, requires the exact authoritative count before
  tail access, and no new parallel audit resumes in this phase.
- REG3119 rejects inserting callback wiring at a similar but wrong options
  boundary and reading a union-only field without retained narrowing. Patch
  inside exact named factories, capture the narrowed result in a definite local
  and typecheck before compiled tests.
- REG3120 rejects embedding JavaScript regular expressions inside a PowerShell
  native argument for copy hashing. Use the repository-owned web-test boundary
  and patch only the exact reported digest literal.
- REG3121 rejects a bounded emulator wrapper that suppresses its small failing
  diagnostic and emits no test summary. After registration expose that bounded
  diagnostic once, classify it, then correct only the proven command boundary.
- REG3122 rejects starting Firebase emulators without the repository-qualified
  bundled JDK when global Java is absent. Expose `JAVA_HOME` and its `bin` only
  to the emulator child and restore the parent environment afterward.
- REG3123 rejects Data Connect emulator success when its Postgres owner reports
  `ECONNRESET` or shutdown failure. Require zero emulator error lines and use a
  direct no-apply schema validator rather than repeating that unstable run.
- REG3124 records the unavailable direct Data Connect SQL-diff read. Do not
  retry or bypass authentication; keep live schema validation pending for a
  later founder-controlled authenticated window.
- REG3125 rejects a tool wrapper whose JavaScript object uses a shell-style
  field token. Use the exact declared call schema and literal known test owners
  instead of repeating discovery.
- REG3126 rejects `.Count` on a PowerShell-unwrapped singleton tool path.
  Normalize candidate paths with `@(...)`, require one scalar and qualify both
  immutable negative and positive APK fixtures before build integration.
- REG3127 records the first authorized FIX7 Dev Data Connect readback stopping
  on Firebase CLI authentication before any cloud mutation. Do not retry or
  source alternate credentials; require founder-controlled Firebase
  reauthentication, then replay regression, coordination and MVP gates before
  one new read-only preflight.
- REG3128 rejects treating a post-reauthentication Data Connect service-list
  exit `1` with only a coarse `other` class as service-state evidence. Register
  first, then parse structured error status/code/reason before classifying an
  HTTP 403. Status alone never proves missing IAM when an Allow policy permits
  access; never infer absence, request redundant roles or print login material.
- REG3129 rejects accepting a zero-exit Hosting list whose remembered field
  projection produced a blank site identity. Enumerate the installed CLI
  result object's property names first, then project only verified fields;
  native exit alone never proves semantic completeness.
- REG3130 rejects using gcloud after its saved default project differs from
  the authorized Dev project. Do not emit or mutate the unrelated default;
  every permitted read carries the exact explicit Dev project and validates
  returned resource scope before an IAM decision.
- REG3131 records explicit-Dev gcloud project metadata failing authentication.
  Do not retry, obtain tokens or import credentials; require a founder-owned
  gcloud login, keep explicit Dev scoping and replay all three gates before a
  new read-only project or IAM preflight.
- REG3132 rejects retrying an IAM Policy Troubleshooter authentication failure
  after ordinary explicit-Dev gcloud reads pass. Do not print tokens or use
  alternate credential surfaces; ask the founder immediately for a read-only
  effective-permission result and keep all mutations at zero.
- REG3133 rejects asking for new IAM roles from a direct-member projection when
  the authoritative Console already shows effective Owner access. Account for
  inherited roles and principal-context mismatch first; request a read-only
  effective-permission result instead of redundant grants.
- REG3134 rejects locating a registry entry with an unqualified identifier that
  also matches its evidence path. Bind the exact quoted JSON `id` property,
  normalize with `@(...)` and require one scalar before range arithmetic.
- REG3135 records exact Data Connect compile returning authentication error
  while the Dev console is still unprovisioned. Do not retry or create blindly;
  ask the founder immediately to expose only the next `Get started` choices,
  inspect them and retain zero cloud mutations until the path is qualified.
- REG3136 repeats the PowerShell statement-form inline-value parser class in a
  read-only APK-state projection. Compute the optional value into a named
  scalar first; never place `if` directly after concatenation or in a property
  value.
- REG3137 rejects a public-auth sideload profile wired to
  `ReviewSocialAuthGateway`: its default cancellation and missing callback
  interface cannot qualify real provider login or X/Instagram returns.
- REG3138 rejects any live public-auth profile that requests limited-use App
  Check tokens without activating the exact Dev Play Integrity provider before
  gateway construction.
- REG3139 rejects device-review composition that exposes all providers or
  forces unavailable methods true. Runtime availability must come from the
  same production qualification contract used by the real gateway.
- REG3140 rejects post-login success that is either a review fake or depends on
  founder-held SQL Connect. The global-auth lane verifies a real Firebase
  session without creating provisional business-domain schema.
- REG3141 rejects a combined MVP current-ticket and long selected-assessment
  replacement built from non-literal rendered context. Patch the ticket scalar
  independently, then use freshly read small exact hunks and project every
  accepted subtree before continuing.
- REG3142 rejects reusing a rendered selected-assessment array after earlier
  incremental state changes. Read the immediate named live array, patch it
  alone and parse/count it before touching the next assessment field.
- REG3143 rejects replaying the MVP gate while selected-assessment identity is
  FIX8 and the active ticket remains FIX5. During bounded recovery, complete
  only the remaining selection identity fields before any runtime action and
  gate the fully consistent state once.
- REG3144 rejects a complete top-level ticket replacement containing one
  manually normalized token instead of literal JSON. Patch scalars first and
  each freshly read named array independently; parse/count every accepted hunk.
- REG3145 rejects retrying whole-array replacement after the same dense MVP
  owner rejects a freshly read block. Substitute one unique current string per
  patch and parse the selected array after every accepted line.
- REG3146 rejects manually transcribing even one long current robustness
  scalar. Project indexed live values, copy the returned scalar exactly, patch
  one line and verify that index before continuing.
- REG3147 rejects an inherited FIX5 gate that cannot recognize the exact
  selected FIX8 repair descendant. Add only the manifest-bound successor branch
  while retaining every FIX5 fact, privacy hold and zero release-action count.
- REG3148 rejects appending Node's dot-reporter option after a positional test
  glob through `npm test --`. Invoke the compiled runner with reporter options
  first, capture native output and emit only bounded explicit totals.
- REG3149 rejects an inherited shared-auth gate that cannot recognize the
  exact selected FIX8 descendant. Add only its manifest-bound source-repair
  branch, preserve all shared protections and restart both cycles after replay.
- REG3150 rejects the inherited FIX1A gate when its descendant set stops at
  FIX5. Add only the exact FIX8 ticket/hash branch, preserve every FIX1A
  protection and unrelated-ticket negative, then restart both cycles.
- REG3151 rejects classifying a compacted unattended-state patch by checking
  the wrong object depth. Read back the exact nested object and never retry
  when that authoritative projection proves the rule already exists.
- REG3152 rejects guessing a generic regression-registry filename. Copy the
  authoritative coordination owner path or recover it with one config-scoped
  exact filename search before parsing.
- REG3153 rejects broad repository-wide registry discovery that truncates its
  output. Constrain recovery to the exact config filename and project only the
  required match.
- REG3154 rejects checking `unattendedAutomation` at top level when the live
  owner nests it under `comprehensiveSuccessorAudit`. Project the parent first,
  correct false absence before retry and do not duplicate the write.
- REG3155 rejects assuming one `resolve-activity --brief` component shape on
  OPPO before projecting it. Guard before force-stop, register rejection, then
  validate one exact resolver result before a separately gated cold launch.
- REG3156 rejects crediting OPPO customer-visible state from one resumed-marker
  pattern. Do not relaunch; inspect bounded power, focus and activity fields
  together and keep screen-off receipts out of visual/performance qualification.
- REG3157 rejects recurring PowerShell interpolation with a colon immediately
  after an unbraced variable in path-line projections. Use `-f` formatting and
  parse before retry.
- REG3158 rejects nested single-range arrays that PowerShell flattens into
  incompatible scalar shapes. Use explicit integer bounds or named objects,
  stop on errors and reject partial reads.
- REG3159 rejects retrying a public-domain web open after the safety layer
  denies it. Register the batched read failure, then use one bounded
  unauthenticated HTTP status/title readback without login or writes.
- REG3160 rejects inferring stale Hosting from a 30-day matcher that also fails
  against current source. Prove the matcher locally before classifying live
  drift or requesting deployment.
- REG3161 rejects requiring `30` immediately followed by `days` without first
  proving the expression against source. Use one bounded flexible matcher for
  identical source/live boolean projections.
- REG3162 rejects a correction patch that repeats an already consumed id as a
  trailing context anchor. Use one unique replacement block and one append
  anchor only.
- REG3163 rejects final YouTube reviewer submission while a source-proven
  30-day deletion maximum is absent from the HTTP-200 public delete page.
  Require exact Hosting promotion and source/live parity after founder review.
- REG3164 rejects final YouTube submission while the audited mobile YouTube
  surface lacks a direct YouTube Terms link required by current Developer
  Policies. Repair only under a successor ticket after FIX8 acceptance.
- REG3165 rejects broad `git status --untracked-files=all` on the huge Windows
  evidence tree when long-path warnings and truncation prevent a complete
  digest. Use the bounded non-emitting owner and credit only native exit zero.
- REG3166 rejects guessing the MVP selected-manifest property depth and
  accepting null. Project the live parent and compare the exact field with the
  independently computed ticket hash.
- REG3167 rejects adding an unproven optional current-ticket projection after
  the selected FIX8 assessment/hash is already proven. Stop projecting it and
  rely on the exact selected assessment plus authorized MVP gate.
- REG3168 rejects reconstructing the FIX8 stable owner list and aggregate
  algorithm from summary. Use the exact preserved build-manifest path inventory,
  rehash live files and verify count/checksum before build.
- REG3169 rejects build-process probes that match their own embedded command
  text. Exclude the diagnostic process and its ancestor hosts, then require a
  separately identified build child plus registered candidate state.
- REG3170 rejects successor manifests reconstructed only from a predecessor
  inventory plus known additions in a dirty tree. Seal the complete live
  tracked and untracked build-input closure and fail on every unexplained
  omission before candidate registration or build.
- REG3171 rejects descriptive coordination task labels that have no active
  claim. Reuse the exact recorded `/root` claim with `-UseRecordedClaim`.
- REG3172 rejects combining new evidence-file creation with an unverified
  mutable coordination-policy tail anchor. Create evidence first, then append
  claims using a freshly read unique policy hunk.
- REG3173 rejects combined MVP authorization patches anchored by a long
  historical approval string. Project and replace each live scalar in separate
  bounded hunks while all execution gates remain closed.
- REG3174 rejects a prebuild manifest sealed before all listed build-control
  owners are finalized. Preserve the stale seal, create a distinct final seal,
  and bind only the live-owner-verified successor checksum.
- REG3176 rejects a multifile correction patch that omits the registry file
  boundary after a source-script hunk. Use separate one-file patches.
- REG3175 rejects claiming a changed gate was listed without projecting the
  manifest. Prove exact membership and include the full invoked prebuild gate
  graph before creating the final successor seal.
- REG3177 rejects passing a runtime-define array through nested `pwsh`, which
  flattens later values into positional arguments. Invoke the APK gate
  in-process, matching the wrapper.
- REG3178 rejects a PublicAuth successor wrapper whose exact runtime-name set
  omits the Dev Social-content endpoint activated by a Social candidate id.
  Repair the profile, test it, and reseal before retry.
- REG3179 rejects readbacks that guess shorthand MVP and public-readiness
  filenames. Recover the authoritative config-scoped owner names before
  repeating the bounded consistency projection.
- REG3180 rejects piping directly from a top-level PowerShell `foreach`
  statement. Collect loop output into an explicit array before formatting the
  bounded projection.
- REG3181 rejects founder-facing PowerShell commands whose literal script path
  inserts a separator before `.ps1`. Resolve the live file, require
  `Test-Path -LiteralPath ... -PathType Leaf`, and preserve ordinary Windows
  PowerShell path syntax before presenting any copy/paste-ready command.
- REG3182 rejects starting Flutter APK assembly before the live Android release
  resource graph is proven linkable. Audit XML references and owners, run a
  dedicated pre-APK resource-integrity gate plus the exact release resource
  task, and create a distinct source seal after any repair; never reuse a
  failed candidate fingerprint.
- REG3183 records a recurrence of REG3166: never guess the MVP selected-ticket
  parent path. Recover the live bounded parent before projecting its hash, and
  reject null as invalid evidence.
- REG3184 rejects Android resource audits that name unproven source-set
  directories. Enumerate live resource roots first and reject mixed
  match/error output as incomplete evidence.
- REG3185 rejects recursive Android-intermediate searches whose output is
  truncated. Query exact release directories and exact resource filenames,
  projecting bounded existence, timestamp and checksum evidence.
- REG3186 rejects using a novel MVP top-level state to journal a failed action.
  Preserve the schema-bound `ticket_disclosed_and_authorized` value and close
  build/install authority through their dedicated execution fields.
- REG3187 rejects byte-hash equality as a proxy for semantic XML equality.
  Parse and normalize XML semantics so harmless line-ending differences do not
  block the Android resource gate.
- REG3188 rejects one obsolete raw `packaged_res` path as a postcondition after
  a successful release resource link. Require native task exit zero and the
  compiled release merge symbol; treat qualifier placement as variable.
- REG3189 rejects restoring a redundant qualifier owner to mask stale Android
  incremental resource state. Preserve the min-SDK-valid obsolete deletion and
  force authoritative release resource recomputation before APK assembly.
- REG3190 rejects leaving an empty obsolete Android qualifier directory after
  deleting its final resource. Verify exact path and zero items, remove only
  that empty directory, then rerun final lint.
- REG3191 rejects bypassing an execution safety-policy denial for an exact
  empty-directory removal. Request immediate founder help for one literal
  PowerShell command, then independently verify absence before final lint.
- REG3192 rejects sealing before every included executable lifecycle checker is
  finalized. Complete checker edits first, verify every manifest row against
  live bytes after sealing, and never overwrite or reuse an invalidated seal.
- REG3193 rejects piping directly from a top-level PowerShell `foreach`
  statement during mandatory reconstruction. Use one independent scalar read
  per owner, or construct a bounded array before any genuine aggregation.
- REG3194 rejects grouping mandatory owner reads into one result when the
  combined output can truncate. Read each owner independently and page large
  owners through verified EOF before relying on them.
- REG3195 rejects a dense JavaScript tool wrapper that fails before its nested
  PowerShell command starts. Use one plain awaited tool call, a simple literal
  command and a plain output projection, then split later locators separately.
- REG3196 rejects sealing a repair retry before every inherited shared-auth
  gate recognizes its exact action-time lifecycle. Replay repair-pending and
  retry-authorized states, then create a distinct seal after all gate changes.
- REG3197 rejects relying on any bounded source read whose tool result is
  truncated. Register it, locate one literal anchor, and retry with only the
  smallest independently bounded slice needed for the decision.
- REG3198 rejects assuming a registry collection name during inspection. Use
  the established top-level `entries` property and register a failed query
  before issuing its corrected form.
- REG3199 rejects assuming a ticket subobject during state readback. Locate the
  exact manifest property first, then project its established parent and reject
  any null or ambiguous result.
- REG3200 rejects reusing an assumed APK state subobject during readback. Find
  the exact property parent first, then parse and compare it without accepting
  null manifest evidence.
- REG3201 rejects assuming a checker filename for help or execution. Resolve
  exact script paths with `rg --files` first and register any failed lookup
  before retrying with the discovered owner.
- REG3202 rejects accepting a non-emitting dirty digest with non-empty stderr
  or an unexplained record-count expansion. Register first, classify without
  emitting paths, preserve all files, and require exit zero plus empty stderr.
- REG3203 rejects ad hoc repository-containment checks in APK or AAB wrappers.
  Canonicalize roots and targets, accept existing and future repo descendants,
  reject traversal and prefix collisions, and exercise the shared gate before
  every artifact-producing build.
- REG3204 rejects monitoring polls whose sleep meets the tool yield while the
  wrapper discards a returned session identifier. Use a shorter sleep and
  always preserve either the final exit or the live session id.
- REG3205 rejects authorizing an APK or AAB from source/registrant checks that
  do not prove the final production plugin closure. Qualify Firebase Core and
  generated registration with a multidex-aware final-output-equivalent gate,
  and forbid `integration_test`, before sealing or sideloading.
- REG3206 rejects using unsupported `--help` on `apkanalyzer dex packages`.
  Use only its displayed supported options and register any nonzero diagnostic
  before issuing a corrected inspection.
- REG3207 rejects multi-file patches without one explicit file header per
  owner. Verify every patch boundary and treat atomic rejection as zero change.
- REG3208 rejects positional registry readback after entries are appended.
  Select the intended incident by exact ID and reject ambiguous array indexes.
- REG3209 rejects discovering obsolete third-party manifest namespace
  declarations only during packaging. Inventory resolved plugins before APK or
  AAB builds, block until dependency migration, and never patch Pub cache.
- REG3310 rejects relying on a source range whose output is truncated at a
  compaction boundary. Discard it, locate one exact anchor, and read only
  independent 10-to-20-line windows needed for the decision.
- REG3311 rejects guessed regression-memory and coordination filenames. Resolve
  exact live owners before reading and never retry a nonexistent conventional
  path.
- REG3312 records a recurrence of REG3280: never pipe directly from a top-level
  PowerShell `foreach` statement. Assign results to a task-specific array first
  or emit bounded scalars independently.
- REG3313 rejects reading a remembered owner path after discovery returned a
  different exact path. Split discovery and reading, then copy only the proven
  owner into the bounded read.
- REG3314 rejects broad recursive dependency searches whose output truncates.
  Once an implementation owner is known, read only its exact error-mapping
  range and discard all partial search output.
- REG3315 rejects assuming a dependency uses Groovy `build.gradle`. Resolve the
  exact build-script owner first and support Kotlin `build.gradle.kts` without
  a failed guessed read.
- REG3316 rejects projecting a complete primary owner array for a two-path
  ownership check. Emit only exact boolean membership results and discard any
  truncated claim projection.
- REG3317 rejects a Google compatibility fixture that constructs
  `PlatformException` without importing `package:flutter/services.dart`.
  Compilation failure invalidates the focused cycle even when sibling tests pass.
- REG3318 rejects declaring `const PlatformException`; its constructor is
  non-const. A repeated fixture compilation failure remains a failed cycle.
- REG3319 rejects expanding a bounded Google-auth repair into the complete
  mobile suite without a qualified full-suite baseline or useful provider
  stopping condition. Use exact affected auth/startup owners and established
  lifecycle gates; never modify unrelated UI or goldens for this repair.
- REG3320 rejects relying on truncated full-suite output for an exact failure
  inventory. Discard every partial chunk, do not replay the unbounded suite for
  this Google repair, and preserve bounded exact-owner exits instead.
- REG3321 rejects invoking the coordination checker without its four mandatory
  identity and registry arguments. Read its live parameter declaration after
  compaction and never accept a parameter-binding rejection as a gate pass.
- REG3322 rejects accepting a successful Kotlin compile whose warning-heavy
  output was truncated. Re-run the same task in quiet plain mode and require a
  complete exit-zero result before qualification.
- REG3323 rejects retrying or speculatively changing the historical C33E Google
  gate after its C33F successor-ticket byte pin moves. Compare exact generations
  first and use the owning lifecycle workflow or document non-applicability.
- REG3324 rejects retrying or weakening FIX5 when its FIX8 lifecycle assertion
  is stale. Recognize only the truthful fail-closed repair state, preserve zero
  release authority and provider requirements, and prove positive/negative cases.
- REG3325 rejects treating Android Credential Manager `canceled` after account
  selection as proof of founder cancellation. Use the pinned native identity
  compatibility bridge, preserve Firebase exchange and require its permanent
  prebuild gate before any separately authorized successor artifact.
- REG3326 records a recurrence of REG3207: every multi-file patch needs an
  explicit file header per owner. Atomic rejection is zero change; retry each
  ticket/evidence owner independently after registration and gate refresh.
- REG3327 records a recurrence of REG3202: a non-emitting dirty digest with
  non-empty stderr is failed even when status exits zero. Classify only bounded
  warning categories, emit no paths, and require a fresh empty-stderr digest.
- REG3328 records a recurrence of REG3243: a full-social runtime profile is not
  proof that X, Instagram or Facebook is qualified. Bind every enabled fact to
  provider-specific non-secret readback and fail closed independently.
- REG3329 rejects APK provenance that always labels Meta inputs absent. Derive
  only a non-secret presence/absence label from exact Facebook-enabled state and
  prove Google-only plus full-provider branches before packaging.
- REG3330 rejects retrying a failed Firebase function-list readback or using
  historical function state as current proof. Use one independent explicit-
  project Cloud Gen2 readback, then ask the founder immediately if it also fails.
- REG3331 rejects retrying after both Firebase and explicit-project Cloud Gen2
  readbacks fail. Ask immediately for founder gcloud reauthentication and Dev
  project selection without requesting or emitting any token or account data.
- REG3332 rejects mixing an existing test owner with guessed provider test
  filenames. Resolve exact paths with `rg --files` first and discard every
  combined lookup that contains a path-not-found error.
- REG3333 rejects using any truncated post-reauthentication Cloud Gen2 readback
  as current function proof. Discard the entire result, refresh all mandatory
  gates, then request only one allowlisted non-secret scalar per invocation.
- REG3334 rejects inferring live binding identities or deployment readiness
  after the public-auth function's source/live secret-binding set comparison
  returns false. Register first, then compare only counts and hashed key sets.
- REG3335 rejects single-letter PowerShell helper names such as `H`, which can
  collide with built-in aliases. Use a task-specific function name, verify its
  command type, and discard every result from the failed invocation.
- REG3336 rejects editing or executing a newly created source owner before its
  exact path is present in the primary coordination claim. Freeze it, register,
  bind the checker and fixture owner, then replay the coordination gate.
- REG3337 rejects using remembered owner-array adjacency in a coordination
  policy patch. Atomic rejection is zero change; read the exact binding and
  script anchors, then patch only those proven contexts.
- REG3338 rejects claiming a nonexistent future fixture owner. Keep only the
  existing checker claim and place its synthetic cases in the already-owned
  build-control test before replaying coordination.
- REG3339 rejects qualifying a focused Flutter suite from exit zero and a final
  pass line when its stream is truncated. Redirect JSON to a unique temporary
  file, parse complete terminal/count evidence, and emit only the summary.
- REG3340 rejects retrying an opaque inline test-capture command after desktop
  policy blocks process creation. Use a fixed repository evidence path, retain
  the JSON log, and parse it in a separate read-only command.
- REG3341 rejects a non-emitting dirty digest that leaks a PowerShell
  `VoidTaskResult` before its JSON. Assign every async result to null and accept
  only exactly one allowlisted JSON line with empty stderr and exit zero.
- REG3342 rejects combined whole-file Facebook adapter and broad symbol output.
  Discard it, locate exact ranges without content, and read sign-in, mapping and
  focused-test owners independently before patching.
- REG3343 rejects building after the native Google identity bridge drifts a
  whole-file approved UI hash. Never rewrite accepted hashes or weaken the
  lock; isolate the provider seam and preserve the accepted region first.
- REG3344 rejects PowerShell projection localization that uses a negative
  `-split` limit and collapses multi-line inputs. Discard it; compare normalized
  hashes first and use verified default newline splitting only when needed.
- REG3345 rejects assuming `FlutterActivity` exposes ComponentActivity result
  registration in the pinned embedding. Inspect the actual hierarchy, use a
  compile-proven callback owner, and retain the accepted-baseline projection.
- REG3346 rejects broad FIX8 lifecycle patches built from remembered nested
  arrays. Atomic rejection is zero change; read and patch status, provider,
  repair, release, authority and device sections independently.
- REG3347 rejects serializing the whole historical MVP pre-ticket checkpoint.
  Discard it and project only the five identity fields plus the exact current
  `selectedTicketAssessment` child permitted by AGENTS.md.
- REG3348 rejects serializing complete APK runtime defines when they contain
  Firebase or provider identifiers. Emit only define names, qualification
  booleans and non-empty presence facts; never repeat an identifier value.
- REG3349 rejects full-social environment preparation that labels the process
  with a historical FIX5 candidate. One validated CandidateId must govern both
  preparation modes before founder prompts or a new source seal.
- REG3350 rejects a final-seal evidence patch anchored to remembered prose
  wrapping. Atomic rejection is zero change; read the live tail and append from
  one literal verified anchor.
- REG3351 rejects a release-authority readback that guesses nested JSON property
  names or a conventional MVP-state filename. Discard every null or path-not-
  found projection, discover the exact live owners and schema first, then read
  only the bounded authorization/count fields before a build or install.
- REG3352 rejects invoking a guessed shortened MVP gate filename. Discard the
  combined path-not-found output, resolve the exact live gate with `rg --files`,
  read its parameter header, and invoke that discovered owner only once.
- REG3353 rejects projecting coordination `activeClaims` as an assumed array of
  role records. Discard the empty result, inspect immediate live property names,
  and use only the exact recorded primary task with `UseRecordedClaim`.
- REG3354 records a recurrence of REG3348: never inspect APK machine state with
  raw line ranges because adjacent runtime configuration may contain private
  identifiers. Parse JSON and emit only allowlisted booleans, counts and hashes.
- REG3355 records a recurrence of REG3202: an abrupt dirty-record expansion is
  not accepted merely because stderr is empty. Preserve everything, register,
  classify generated versus non-generated counts without paths, and require the
  independent sealed-owner comparison before a build.
- REG3356 rejects indexing a filtered executable-path pipeline without first
  wrapping it as an explicit array. A single path otherwise collapses to a
  string and index zero becomes one character; discard and retry only after
  exact candidate-count validation.
- REG3357 rejects combining an external install mutation with a later summary
  object containing bare JSON-style booleans. If projection fails after ADB ran,
  consume authorization, never reinstall, and use only independent installed-
  version and cold-start readbacks to classify the outcome.
- REG3358 makes version history permanent for every APK, AAB, OPPO and Play
  action. Require predecessor and candidate versions, versionCode, source seal,
  artifact checksum, action counts and post-action readback; reject unversioned,
  duplicate, history-free or ambiguous release mutations.
- REG3359 rejects r60.83 Google device acceptance with retained sanitized code
  `auth-unknown`; the native/Firebase exception boundary remains unclassified.
- REG3360 rejects r60.83 YouTube device acceptance with the same `auth-unknown`,
  proving failure remains in shared Google identity before YouTube continuation.
- REG3361 rejects r60.83 Facebook device acceptance with retained sanitized code
  `auth-facebook-firebase-provider-failure` at Firebase credential exchange.
- REG3362 rejects r60.83 X device acceptance with `auth-provider-unavailable`,
  proving a pre-authorization runtime availability rejection.
- REG3363 rejects r60.83 Instagram device acceptance with
  `auth-provider-unavailable`, also before authorization launch. No provider
  retry, rebuild or reinstall is permitted before source-boundary classification.
- REG3364 records a recurrence of REG3312: never pipe directly from a top-level
  PowerShell `foreach`. Populate an explicit results array, then serialize it.
- REG3365 rejects guessing conventional backend source/test roots during auth
  forensics. Resolve exact current owners with `rg --files` before searching.
- REG3366 records another REG3348/REG3354 boundary recurrence: never include an
  identifier-bearing runtime-state owner in a source search. Compare internally
  and emit only endpoint/scope/callback match booleans.
- REG3367 rejects patching Facebook enum/code/message switches from remembered
  prose. Atomic rejection is zero change; read and patch the exact live block.
- REG3368 rejects parallel Flutter test processes in one checkout because they
  share a non-concurrency-safe test cache. Serialize Flutter suites; retain only
  independently completed groups and rerun the unexecuted group after gates.
- REG3369 records another REG3339 truncation: a visible terminal pass line is
  insufficient. Retain JSON output, parse every record and emit only counts.
- REG3370 rejects a closed compile session when the final poll projected only
  stdout and dropped `exit_code`. Re-run only after gates and serialize status.
- REG3371 rejects assuming the installed gcloud exposes an Identity Platform
  config command. Resolve a supported Firebase/REST read-only owner first.
- REG3372 rejects trimming a null ADB directory-check result. Capture explicit
  arrays, join null-safely and keep gallery readback bounded to two files.
- REG3373 forbids retaining an inspected screenshot copy containing a private
  email address. Record only sanitized UI state and delete exact local copies;
  OPPO originals remain untouched.
- REG3374 rejects combining computed validation and deletion for private image
  cleanup. Use one literal non-recursive `Remove-Item` per verified local copy.
- REG3375 records that literal `Remove-Item` is also blocked here. Do not switch
  shells; delete the exact copied owners through the repository patch mechanism.
- REG3376 records that `apply_patch` cannot delete non-UTF-8 JPEG binaries. Ask
  the founder immediately for exact literal cleanup, then verify absence only.
- REG3377 rejects Email Link local cycle one: 26 passed and one failed. Parse
  only the retained failed assertion after gates, fix once and use a new cycle.
- REG3378 rejects using `$error` as a task variable because it collides with
  PowerShell's read-only `$Error`. Use task-specific failure-event names.
- REG3802 rejects delegated checkpoint reads that exceed the live thread
  reader's bounded turn limit. Use the callable parameter contract, request at
  most 10 turns and page only when a returned cursor proves it is necessary.
- REG3803 rejects grouped ticket-identity searches that return no usable
  projection. Search config and quality roots independently, normalize no-match
  exits separately and accept only explicit bounded counts and exact matches.
- REG3804 rejects a coordination binding patched with a pending digest
  placeholder. Recompute the exact registry count and SHA-256 after every
  append, then copy those scalars directly into one bounded binding update.
- REG3805 rejects thread-history reads whose per-item output request exceeds
  the live 20000-character limit. Validate both the 10-turn and 20000-character
  bounds before the call and reuse them unchanged on every cursor page.
- REG3806 rejects a ticket-history assertion that hides whether native exit or
  parent cardinality failed. Capture the git exit immediately, normalize the
  one parent row separately and assert its exact two-token non-merge shape.
- REG3807 rejects coupling those parent checks after a valid current-history
  projection still fails. Assert native exit, row count and token count
  independently, then assign the parent only after all three pass.
- REG3808 rejects split-array cardinality as the final parent-history oracle.
  Match the one native row against the exact child-space-parent SHA pattern,
  then extract the parent only from that qualified row.
- REG3809 rejects formatted parent-row regex parsing after valid Git evidence
  still fails. Resolve the parent with `rev-parse commit^` and independently
  require an empty `--min-parents=2` probe for the first ticket commit.
- REG3810 rejects `rev-list --min-parents=2` for commit-local classification
  because it scans merge ancestors. Project `%P` from the exact commit, require
  one parent SHA and compare it with `rev-parse commit^`.
- REG3811 rejects comparing two formatted direct-parent representations when
  ticket history is the invariant. Resolve the base with `commit^`, then require
  zero merges only inside the exact `base..HEAD` ticket range.
- REG3812 rejects an aggregate ticket-range merge result without exact identity.
  Project only merge commit IDs and parent counts, preserve existing history and
  use a literal compatibility rule only for a founder-approved retained merge.
- REG3813 rejects guessed design tokens such as `MoolColors.outline`. Inspect
  the exact declaring owner, use only a current member and pass focused analysis
  before running widget behavior.
- REG3814 rejects any source correction after registry movement and before gate
  refresh. Replay the implementation regression and existing codex_ui
  incremental gates immediately after every append and binding update.
- REG3815 rejects a themed full-width OutlinedButton placed directly inside a
  Row. Give horizontal action buttons finite local width and a finite minimum
  height of at least 44 pixels, then render the paused state at compact width.
- REG3816 rejects `ensureVisible` for an unbuilt lazy Conversation Info child.
  Use bounded `dragUntilVisible` on the keyed list, then measure the constructed
  later tile.
- REG3817 rejects replaying the retired C10D static dock-shape checker against
  the approved contextual Chat shell. Use the current shell suite, exact-return
  widget journey and incremental lane gate unless that checker gains a successor mode.
- REG3818 rejects passing raw Git reverse-diff range hunks into `apply_patch`.
  Restore generated text from independently read current and HEAD content using
  the patch tool’s native whole-file update shape.
- REG3819 rejects grouped RuntimeUiReview build-control searches across scripts
  and config. Read the exact wrapper and foundation checker independently, then
  follow only their returned machine-state contract.
- REG3820 rejects manually completing a short commit into a candidate HEAD.
  Project `git rev-parse HEAD` immediately before state creation, copy the exact
  scalar and compare parsed state before any build gate.
- REG3821 rejects reusing absent candidate-specific premium-motion evidence.
  Keep the canonical policy and coverage, but bind the candidate contract and
  disposition to exact existing current-ticket owners before the APK gate.
- REG3822 rejects PowerShell dot access for UIAutomator attributes such as
  `content-desc`. Use `GetAttribute` with exact literal names and resume from
  the retained capture without repeating the device action.
- REG3823 rejects a third compact conversation-header action after r61.34
  overflowed by 16 pixels on OPPO. Keep Voice and Video visible, open shared
  Conversation Info from the identity/title and test final header geometry.
- REG3824 rejects header corrections based on pre-format source context. Read
  exact current title and trailing ranges, patch them independently and format
  only after both bounded changes are verified.
- REG3825 rejects repeating a conversation tap after r61.35 first showed a
  blank blue OPPO surface. Preserve the frame and classify activity focus,
  process, hierarchy ownership and sanitized fatal markers before correction.
- REG3826 rejects attributing a Shop-specific device defect to the global Chat
  owner. Identify the visible route/source semantics first; keep Shop Cursor-owned
  and qualify global Conversation Info from a non-Shop context such as Work.
- REG3827 rejects a visually 48-pixel Chat recovery button whose OPPO exported
  bounds are only about 31 logical pixels. Lift shared recovery sheets by the
  existing Android semantics-clearance token and require at least 44 exported.
- REG3828 rejects calculating that clearance inside a `useSafeArea` modal after
  its top inset is removed. Compute from the caller context and pass the exact
  scalar into the sheet wrapper.
- REG3829 rejects changing a shared Chat sheet constructor before updating all
  consumers. Inventory every call site and pass caller-owned clearance through
  every sheet launch before focused analysis.
- REG3830 rejects combining regression-memory and incremental pre-build gates
  in one shell. Run each authoritative gate separately with its own exit before
  APK state validation and wrapper preflight.
- REG3831 rejects empty inbox actions that cross the compact navigation boundary
  by three pixels. Add an asymmetric bottom reserve and require both final 44+
  pixel controls to remain fully above the fixed NavigationBar.
- REG3832 rejects a bottom-reserve patch that does not move the actual empty
  action group. Read the exact `_EmptyInbox` range and bind geometry directly
  to its keyed controls before retrying the compact rect assertion.
- REG3833 rejects a hardcoded compact NavigationBar y-coordinate. Compare the
  action rects to the rendered `chat-native-navigation` rect and require exact
  non-overlap instead of nominal-height arithmetic.
- REG3834 rejects an empty action that still overlaps the rendered NavigationBar.
  Project all three rects, then move the keyed action group by the smallest
  explicit layout offset that preserves 44-pixel targets and proves zero overlap.
- REG3835 rejects assuming the empty-inbox Open Feed key for the full journey.
  Seed one real thread, enter Discover through `chat-new`, then open Feed and
  return to the loaded people list for connect-to-direct-Chat completion.
- REG3836 rejects a Discover empty action after people have loaded. Use the
  persistent Social `chat-more` → `Open public Feed` entry for the complete
  populated Feed-to-Discover-to-direct-Chat journey.
- REG3837 rejects an unencoded nested `/app/social?sub=feed` return query. Encode
  the complete Social URI as one Chat return value before asserting the Social
  title and persistent Feed menu action.
- REG3838 rejects restricting the persistent public Feed menu to Social-origin
  Chat. Expose one shared Feed entry in every context and preserve the exact
  originating Chat route on native Back.
- REG3839 rejects assuming Android Back pops a Social root directly to Chat.
  Preserve Social shell Back ownership, continue through its global Chat action
  and verify Chat Back returns to Feed within the approved navigation contract.
- REG3840 rejects letting the shared Chat exact-return fallback override an
  attachment tray that consumed Android Back. Close the tray and its notice
  first, keep the conversation mounted and use the route fallback only on the
  next Back action.
- REG3841 rejects skipping the shared inbox when returning from a Feed author
  conversation. Verify thread → inbox → originating Feed, then continue the
  successful journey through Discover and a second direct Chat.
- REG3842 rejects confirming a scrolled Conversation Info change only in an
  offscreen summary card. Keep that summary and also show immediate floating
  feedback for every session-local Chat or call availability change.
- REG3843 rejects retaining the clinic-only Care allowlist oracle after task
  and support destinations are added. Synchronize the audited set and prove
  each deep thread returns under its actual contextual filter.
- REG3844 rejects calling `ensureVisible` before a lazy Conversation Info tile
  exists. Scroll the real keyed list until Safety is rendered, then assert and
  tap the context-specific destination.
- REG3845 rejects using a People thread under the Work business filter for a
  shared Back test. Choose an unfiltered origin or a context-compatible thread
  before exercising transient surfaces.
- REG3846 rejects using audit shorthand as an APK candidate family. Keep Chat
  RuntimeUiReview candidates under `UAW-CODEX-*`, bind the same id in state and
  runtime defines, and run the direct gate before the wrapper.
- REG3847 rejects a Chat sheet action clipped behind OPPO navigation. Reuse the
  shared bottom-sheet clearance owner, retain keyboard scrolling and require
  the final 44-pixel action to stay above the exported safe bottom.
- REG3848 rejects deriving safety identity only from the operational filter.
  Model person/business/conversation separately so an individual helper never
  receives business-blocking wording.
