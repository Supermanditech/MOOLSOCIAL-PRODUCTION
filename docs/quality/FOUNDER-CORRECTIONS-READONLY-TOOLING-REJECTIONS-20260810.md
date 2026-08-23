# Founder corrections read-only tooling rejections — 2026-08-10

## Scope

This evidence records twenty-four tooling, contract and design-process failures during the founder-
authorized Social and Shop correction audit. None mutated Flutter runtime,
backend, APK state, installed application state or protected device evidence.

## Rejections

1. A file-line-count formatter piped directly after a PowerShell `foreach`
   statement and was rejected by the parser before the inventory completed.
2. A combined read of multiple Flutter source ranges and a full file diff
   exceeded the bounded tool output and returned truncated evidence.
3. The audit guessed `docs/quality/PERMANENT-REGRESSION-MEMORY.md`; that path
   does not exist. Repository inventory resolved the durable owners as
   `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md` and
   `config/codex-development-regression-registry.json`.
4. An optional ripgrep lookup for recent registry IDs returned the valid
   no-match exit code 1, but the shell harness surfaced it as a failed script.
5. The first Screen 04 owner read guessed a stale feature-layer path. Inventory
   resolved the live owner as
   `apps/mobile/lib/ui_v2/social/screen04_universal_components.dart`.
6. A Shop Offers search passed Windows wildcard path arguments directly to
   ripgrep. Ripgrep rejected those two path arguments even though earlier
   exact-source matches were still returned through the pipeline.
7. The first machine-ticket JSON readback again piped directly after a
   PowerShell `foreach`, despite REG956's prevention rule, and was rejected
   before either JSON document was validated.
8. A directory-wide `flutter test test/ui_v2/universal` run mixed the current
   shell tests with a large stale historical matrix, failed 87 legacy tests and
   exceeded bounded output. FSC01's focused cases passed inside the run, but
   the truncated aggregate cannot be accepted as completion evidence.
9. The bounded current-owner suite found two predecessor tests that still
   required a family-root cell for every family. They correctly failed after
   the founder-authorized Social-only removal; all other tests in that bounded
   group passed.
10. A second attempted current-owner group selected tests merely because they
    construct `MoolDestinationNavigationV2`. It included C20/C22/C23 suites
    whose assertions target already-removed capsule, strap, bridge and
    Home-launcher owners; 22 unrelated failures and truncated output resulted.
11. The next bounded production-conformance group found a third uniform
    predecessor assertion in C27D that called `getSize` on Social's now-absent
    root. The other three real-family conformance tests in that group passed.
12. The first atomic FSC01-completion/FSC06-selection patch was rejected because
    one large expected JSON section did not exactly match live punctuation.
    Readback proved all three target files remained unchanged.
13. The first FSC06 focused group found two current conformance expectations
    that still required a Shop local `shop` cell and selected indicator. The
    catalogue tests and all ten Buy route-continuity tests passed.
14. The next current route-projection group found one C25E expected-action list
    that still included local `shop`. All 16 other executed cases in that group
    passed and one existing capture case remained skipped.
15. An unbounded `git diff --check` covered the entire preserved dirty tree and
    exceeded the bounded tool output. Its result was truncated and is not
    accepted as ticket evidence.
16. The first REG973 registry entry placed the command label
    `git diff --check` in its `gates` array. The regression-memory validator
    correctly rejected that non-path value as missing repository evidence.
17. The first FSC03 native-owner metadata inventory repeated the direct
    PowerShell `foreach`-to-`Format-Table` parser shape. It stopped before any
    requested source file was read and changed no product, screenbook, scope,
    build or device state.
18. The first combined FSC03 HTML-owner ripgrep used a double-quoted
    alternation expression containing escaped quotes. PowerShell changed the
    intended expression and ripgrep rejected an unclosed group before reading
    the screenbook source; no file or runtime state changed.
19. The first FSC03 browser CTA assertion passed a regular expression to the
    in-app browser `expectNavigation.url` field, which accepts a string. The
    assertion wrapper rejected that matcher after the click reached the exact
    existing Create URL; readback confirmed the destination before any further
    interaction.
20. The installed Computer Use skill directed `sky.documentation(...)`, but
    the loaded runtime exposed no such method. The call stopped before Windows
    automation; the complete skill-owned guidance, confirmations and API files
    were then read directly.
21. A visible Edge `Start-Process` launch for founder review was blocked by host
    policy before execution. No Edge process or window was created, and the
    shell path was not retried through alternate syntax.
22. Computer Use found the installed `MSEdge` app, but both the initial and one
    documented retry of `sky.launch_app` failed because the action execution
    context was unavailable. A fresh inventory proved Edge remained stopped
    with zero windows, so Computer Use stopped and the tested Chromium review
    tab was shown instead.
23. The FSC03 Feed HTML candidate was visually polished in isolation but the
    founder rejected it because it did not begin from the earlier founder-
    supplied X journey references or resolve the complete Social ownership
    system before proposing a generic empty-state CTA. No Flutter work used
    the rejected candidate and its exact HTML/evidence remain preserved.
24. A read-only handoff search combined three optional ripgrep probes without
    declaring zero-match behavior. The valid exit code 1 from an absent term
    surfaced as a failed command and proved no handoff inventory. The command
    changed no repository, browser, app or OPPO state.
25. The first FSC02A native Shorts patch helper assumed the functions.exec
    JavaScript isolate exposed `atob`. It did not, so the helper stopped before
    `apply_patch` received any repository mutation.
26. A retry substituted `TextDecoder` without proving that global existed in
    the isolate. It also stopped before `apply_patch`, and direct literal patch
    input became mandatory for the next attempt.
27. A later FSC02A native cleanup patch included overlapping hunks copied from
    an earlier source snapshot. `apply_patch` verification rejected the stale
    context; the live Flutter owner had to be read again before smaller cleanup
    hunks could be attempted.
28. The first FSC02A test migration bundled three files, and the source-test
    hunk expected one blank line that was absent in the live file. Verification
    rejected the complete patch before any test mutation, so each test owner
    must now be changed and verified independently.
29. The first focused Flutter analysis after the native Shorts rewrite found
    twelve warnings: seven legacy Shorts widgets or methods and five fixture-
    only optional fields were orphaned by removal of the fabricated catalogue.
    No build or device action occurred; zero-warning cleanup is required before
    the bounded analysis can pass.
30. The FSC02A post-implementation evidence update replaced the gate-owned MVP
    top-level authorization state with a descriptive progress string. Delivery
    lock validation passed, but the MVP scope gate rejected that unrecognized
    state before the regression-memory gate ran. No runtime or device changed.
31. The first FSC02B handoff search passed a guessed founder-batch manifest path
    that did not exist. The exact FSC02B ticket read succeeded, but ripgrep then
    exited 2 and the combined command could not prove any broader batch owner.
32. The first FSC02B MVP transition bundled several JSON sections and depended
    on a hand-copied FSC02A test-plan line that did not match the live state.
    `apply_patch` rejected the complete transition before any scope state changed.
33. The first FSC02B Videos widget replacement crossed one large punctuation-
    rich source block through a JavaScript string. The orchestration parser
    rejected the literal before `apply_patch`, so no Flutter source changed.
34. The bounded retry changed to a JavaScript template literal but kept the
    Windows backslash patch path. The parser treated `C:\...` as an invalid
    Unicode escape and again stopped before `apply_patch` or source mutation.
35. The generated FSC02B catalogue-deletion patch ended at the visible
    `End Patch` marker without its required terminal newline. Patch validation
    rejected it before the fixture block or any source line changed.
36. A retry added and asserted a terminal newline, but the patch validator still
    did not see `End Patch` as the last parsed line. No exact serialized-tail
    inspection had occurred, so another generated retry was stopped.
37. The first focused FSC02B analysis found one orphaned test helper:
    `scrollToClearBottomAndTap` lost its final call when the global navigation
    test stopped opening a fixture video. No runtime issue or build occurred.
38. The first combined FSC02B replay included the predecessor C03 global Mool
    navigation suite because one case mentioned the removed fixture title. All
    six C03 cases failed on already-removed navigation keys, while the current
    C28F/Screen 04 and FSC02B tests in the same run passed.

## Permanent prevention

- Capture loop output into a named collection before piping.
- Read one exact source owner or one numeric range per command, and inspect a
  bounded diff separately.
- Resolve durable owners through `rg --files` and use only returned paths.
- Use `Select-String` or explicitly handle ripgrep exit code 1 for optional
  discovery.
- Resolve the exact live source path from inventory before every owner read.
- On Windows, inventory candidate files first or pass exact directories to
  ripgrep; never use unresolved wildcard path arguments.
- Treat named collection capture as mandatory for every PowerShell loop; do not
  rely on memory at the formatting site.
- Select impacted current-owner tests from exact source references and run them
  in bounded groups. A noisy historical directory is diagnostic only unless
  its complete output and ownership relevance are proven.
- When the founder reverses an exact placement contract, migrate predecessor
  tests to assert the new exception while retaining geometry, direct-action and
  unaffected-family coverage.
- Direct construction of a shared widget is not sufficient test relevance.
  Require assertions against live keys/routes or current C24+ production
  contracts before including a predecessor suite in a completion gate.
- Search every current production-conformance helper for a changed key, not
  only direct top-level expectations, before declaring contract migration
  complete.
- Transition ticket manifests, batch state and scope state in small exact
  patches. Read the live raw section first and never make an all-or-nothing
  multi-owner patch depend on a long hand-copied JSON block.
- The Shop root owns the selected Shop state after Products removal. Current
  tests assert no local Shop cell/indicator, an intact Shop root, and selected
  local indicators only for Wholesale or Orders.
- Route projection expresses Shop through the retained family-root key and
  treats only Wholesale and Orders as local actions.
- Run `git diff --check` only against the exact selected-ticket paths in this
  large inherited dirty tree; never treat a truncated repository-wide result
  as evidence.
- Registry `gates` values must be existing repository file paths. Describe
  non-file commands in the prevention text and keep only real gate scripts in
  the machine-readable array.
- Before FSC03 selection, collect every multi-file metadata projection in a
  ticket-specific array and format only after enumeration completes.
- For FSC03 HTML-owner discovery, use separate single-quoted ripgrep
  fixed-string patterns with repeated `-e` options, followed by exact numeric
  range reads; do not cross PowerShell quoting layers with one combined regex.
- Browser CTA navigation assertions use the exact absolute destination string.
  After a wrapper rejection, inspect the live URL before deciding whether the
  action occurred; never repeat a potentially completed click blindly.
- If `sky.documentation` is absent, read the skill-owned guidance,
  confirmations and API files directly before Windows automation.
- Do not bypass a policy-blocked visible browser launch with alternate shell
  syntax. Use the supported app inventory/launcher or visible in-app Chromium.
- Retry a Computer Use launcher failure only once, refresh installed-app state,
  and stop if the exact target still exposes zero windows.
- Before another Social design candidate, inventory and classify every founder-
  supplied reference for that destination, resolve provider-versus-MoolSocial
  ownership and write the screen-specific interaction/state contract. A
  generic isolated CTA card is not a reference-led Social design.
- Keep optional ripgrep probes separate from required reads and explicitly map
  exit code 1 to a zero-match result; only exit codes above 1 are command
  failures.
- Do not assume browser or Node decoding globals exist in the functions.exec
  isolate. Use direct literal `apply_patch` input unless a helper is explicitly
  documented by the active tool contract.
- After an orchestration-global failure, do not cycle through other guessed
  globals. Return to the documented patch interface and exact source context.
- Re-read the exact live source after each material mutation, then apply stale
  cleanup as small, non-overlapping hunks whose context is proven current.
- Patch test owners independently with minimal exact live context; do not make
  several valid migrations depend on one large whitespace-sensitive hunk.
- After replacing a production surface, use the focused analyzer to enumerate
  every orphaned owner and fixture-only field, prove zero references, and remove
  all of them before treating the native implementation as complete.
- Preserve `ticket_disclosed_and_authorized` as the active MVP scope gate state;
  record implementation, host and device progress only in dedicated assessment,
  checkpoint and evidence fields.
- Resolve batch and ticket manifests through `rg --files` before content search,
  and keep known exact reads independent from optional owner discovery.
- Transition MVP scope with small freshly read blocks for assessment, ticket and
  authorization state; do not make the full transition depend on copied text.
- Split punctuation-rich Flutter replacements into small exact patch hunks and
  avoid large orchestration literals that add a second parsing surface.
- In JavaScript template literals, use forward-slash absolute patch paths so a
  Windows backslash can never be interpreted as an escape sequence.
- Validate generated patch suffixes and terminate the exact `End Patch` marker
  with one newline before calling `apply_patch`.
- After any generated end-marker rejection, inspect the exact serialized tail;
  do not alternate line-ending assumptions without evidence, and prefer bounded
  literal hunks when the generated parser shape remains unclear.
- After fixture-driven test migrations, remove helpers whose final call was
  deleted before the next focused analyzer replay.
- Do not include a historical navigation suite solely because it mentions a
  changed fixture. Prove current live-key relevance first; otherwise restore it
  untouched and use the accepted C28F/Screen 04 navigation owners.
- Do not assume browser base64 helpers such as `atob` exist in the orchestration
  isolate. Validate the decoder or use a runtime-neutral text transport before
  generating a bounded apply-patch mutation.
- Prefix every unchanged anchor in a generated unified-diff hunk with one
  space; validate both hunk boundaries before invoking apply-patch.
- Strip trailing line breaks from generated deletion segments before appending
  a separately prefixed unchanged anchor, so blank-line counts remain exact.
- After removing a bounded UI owner, audit every private callback it used and
  remove only zero-reference helpers before the next focused analyzer replay.
- Treat ripgrep exit 1 as success only in an explicit expected-no-match audit;
  capture the result and reject codes above 1 so empty evidence stays truthful.
- Mount indeterminate loading indicators with a finite pump; do not use
  pump-and-settle while a perpetual progress animation remains in the tree.
- After any test-file stall, run each named case separately with an explicit
  timeout and inspect its async owners before retrying the combined file.
- After terminating a Flutter test cell on Windows, inspect exact descendant
  command lines and stop only processes proven to belong to that test.
- Re-resolve the live descendant set immediately before cleanup; validate each
  remaining target rather than requiring already-exited process IDs.
- Validate Flutter process roles separately: the dartvm test runner may carry a
  relative test path while compiler and tester children carry repository paths.
- Run delayed gateway setup inside `tester.runAsync` before mounting widgets;
  awaiting real `Future.delayed` directly under fake time will stall.
- Check optional Android media directories for existence before listing them;
  do not let an absent conventional path fail a successful evidence read.

The installed OPPO r60.27 identity and all C28D rejection evidence remain
unchanged. This record grants no build, install or protected-runtime authority.
# FSC02A1 nullable provider metadata analyzer failure — 2026-08-11

The first focused FSC02A1 analyzer replay rejected the new Shorts composition because `_ShortData.views` and `_ShortData.published` are truthful nullable provider fields while `_YouTubeShortsStageMetadata` initially required non-null strings. No test, build or device work followed the failure. The correction keeps both fields nullable in the renderer and omits absent values instead of fabricating a metric or date. Permanent prevention is registered as `REG-20260811-1058-FSC02A1-NULLABLE-PROVIDER-METADATA-ANALYZER-FAILURE`.

# FSC02A1 moved metadata source-test boundary — 2026-08-11

The first FSC02A1 source-test replay retained two predecessor assertions inside the `_buildLiveYouTubeShort` substring even though the channel key and playback-ownership sentence had moved into `_YouTubeShortsStageMetadata`. The failure occurred before the focused widget replay. The correction verifies those stable contracts in the complete current production source while rendered ownership remains covered by the compact widget test. Permanent prevention is registered as `REG-20260811-1059-FSC02A1-MOVED-METADATA-OWNER-SOURCE-TEST-FAILURE`.

# FSC02A1 Videos source boundary after paused Feed work — 2026-08-11

The corrected FSC02A1 source replay next found that the Videos substring still ended at the removed `_quickPostReady` Feed getter. That following-surface helper disappeared during the preserved but paused FSC03A source work, so it was no longer a lawful Videos boundary. The test now ends at the stable peer method `_buildFeed()`. Permanent prevention is registered as `REG-20260811-1060-FSC02A1-VIDEOS-SOURCE-BOUNDARY-REMOVED-FEED-GETTER-FAILURE`.

# FSC02A1 OPPO screenshot manifest filename mismatch — 2026-08-11

The pre-closure evidence check found that the second OPPO screenshot filename in the FSC02A1 ticket used a remembered suffix that did not match the retained file. The screenshot remained intact in the evidence directory and no runtime work depended on the bad reference. The manifest now uses the literal inventoried filename and verifies every declared screenshot exists before sealing. Permanent prevention is registered as `REG-20260811-1061-FSC02A1-OPPO-SCREENSHOT-FILENAME-SUFFIX-MISMATCH`.

# FSC02C PowerShell ripgrep escaped-quote recurrence — 2026-08-11

A read-only profile-source-set inventory used backslash-escaped quotes inside a PowerShell ripgrep argument. Ripgrep treated the broken remainder as a missing path and exited 2; no mutation followed. The retry uses independent single-quoted fixed-string patterns and explicit optional-match handling. Permanent prevention is registered as `REG-20260811-1062-FSC02C-POWERSHELL-RIPGREP-ESCAPED-QUOTE-RECURRENCE`.

# FSC02C missing Android library profile build type — 2026-08-11

The first Gradle project-configuration gate rejected `getByName("profile")` because the isolated Android library had only the default debug and release build types. Flutter's application profile variant does not automatically create a matching source set in this library configuration. No Kotlin compile or APK task ran. The correction explicitly creates the profile library build type before configuring the reused native implementation source directory. The generated Gradle problem report is preserved. Permanent prevention is registered as `REG-20260811-1063-FSC02C-MISSING-ANDROID-LIBRARY-PROFILE-BUILD-TYPE`.

# FSC02C corrective multi-file patch hunk-marker rejection — 2026-08-11

The first correction for the missing profile build type bundled Gradle, gate and test edits but left an extra hunk marker before the third file header. `apply_patch` rejected the input atomically, and explicit readback confirmed all three intended tokens remained absent. The retry is split into one exact patch per freshly read owner. Permanent prevention is registered as `REG-20260811-1064-FSC02C-CORRECTIVE-MULTIFILE-PATCH-HUNK-MARKER-REJECTION`.

# FSC02C Android library BuildConfig generation disabled — 2026-08-11

The first exact `compileProfileKotlin` gate reached the reused native player but failed because AGP 9 had not generated a BuildConfig class for the isolated library. Both `BuildConfig` references were unresolved; no APK assembly ran. The correction explicitly enables the library BuildConfig feature, keeping `BuildConfig.DEBUG` false for the release-derived profile variant. The Gradle problem report is preserved. Permanent prevention is registered as `REG-20260811-1065-FSC02C-ANDROID-LIBRARY-BUILDCONFIG-GENERATION-DISABLED`.

# FSC02C completion manifest hash reseal order — 2026-08-11

The first final delivery gate ran after FSC02C completion evidence changed the ticket JSON but before its selected-assessment digest was resealed. The delivery lock correctly rejected the stale SHA-256 before scope or regression closure could be claimed. The correction finalizes all ticket evidence, calculates the final hash, updates the single dependent digest and verifies equality before rerunning gates. Permanent prevention is registered as `REG-20260811-1066-FSC02C-COMPLETION-MANIFEST-HASH-RESEAL-ORDER-FAILURE`.

# FSC02D unchanged checkpoint hash transcription — 2026-08-11

The first FSC02D scope-state rewrite accidentally combined the unchanged pre-ticket checkpoint digest prefix with the new ticket manifest digest. The mistake was found by immediate readback before any delivery, scope, cloud, build or device gate ran. The correction restores the checkpoint digest verbatim from the prior state and independently compares both invariant and selected-ticket hashes before qualification. Permanent prevention is registered as `REG-20260811-1067-FSC02D-UNCHANGED-CHECKPOINT-HASH-TRANSCRIPTION-FAILURE`.

# FSC02D authorization evidence label instead of file path — 2026-08-11

The first FSC02D delivery lock passed, but the scope gate rejected the authorization evidence because the field contained a founder-message label rather than an existing repository file path. No cloud, build or device command ran. The correction points both disclosure and authorization evidence to the registered FSC02D preselection document and keeps the message provenance in the acceptance text. Permanent prevention is registered as `REG-20260811-1068-FSC02D-AUTHORIZATION-EVIDENCE-LABEL-NOT-PATH`.

# FSC02D Cloud SDK unavailable on active PATH — 2026-08-11

The first bounded CLI identity probe stopped at local command discovery because neither `gcloud.cmd` nor `gcloud` resolved on the active PowerShell PATH. Firebase identity, cloud inventory and provider endpoints were not reached. The retry audits only repository-local launchers and checks each required executable independently before any cloud script is invoked. Permanent prevention is registered as `REG-20260811-1069-FSC02D-GCLOUD-NOT-AVAILABLE-ON-ACTIVE-PATH`.

# FSC02D Firebase inventory diagnostic suppressed too early — 2026-08-11

The first exact-project Firebase inventory returned nonzero, but the wrapper suppressed stderr and replaced the real diagnostic with a generic exception before the cause was known. Local help subsequently confirmed the positional platform argument is supported. The retry keeps bounded diagnostic stderr until authenticated exact-project access is proven, then filters the non-secret result. Permanent prevention is registered as `REG-20260811-1070-FSC02D-FIREBASE-INVENTORY-ERROR-SUPPRESSED-BEFORE-DIAGNOSIS`.

# FSC02D computer-control skill locator stale — 2026-08-11

The advertised computer-control skill file was absent at its exact session-provided plugin-cache locator when the founder offered to enter an interactive Cloud password. No broader user-directory scan was performed. The fallback is a founder-visible official terminal or browser authentication flow only when required; Codex will not type, capture, copy or echo credentials. Permanent prevention is registered as `REG-20260811-1071-FSC02D-COMPUTER-USE-SKILL-LOCATOR-STALE`.

# FSC02D Firebase exact Dev app inventory generic failure — 2026-08-11

The supported exact-project `firebase apps:list ANDROID` command reached the installed CLI but returned a generic failure and wrote `firebase-debug.log` without listing the Dev app. The login inventory alone therefore does not qualify the authenticated management session. Only bounded status/error lines may be inspected; if the session is expired, the founder must enter credentials in the official interactive flow. Permanent prevention is registered as `REG-20260811-1072-FSC02D-FIREBASE-EXACT-DEV-APP-INVENTORY-GENERIC-FAILURE`.

# FSC02D Google Cloud installer download/launch policy block — 2026-08-11

The first Google Cloud CLI installation attempt combined the official executable download, Authenticode verification and visible launch in one PowerShell command. The desktop execution policy rejected the command before it ran, so no installer was downloaded or opened. The retry uses the host package manager's named verified package and separates installation from founder-controlled authentication. Permanent prevention is registered as `REG-20260811-1073-FSC02D-GCLOUD-INSTALLER-DOWNLOAD-LAUNCH-POLICY-BLOCK`.

# FSC02D Google Cloud winget user scope unavailable — 2026-08-11

The verified `Google.CloudSDK` 579.0.0 package was found from the winget source, but forcing `--scope user` produced “No applicable installer found” and stopped before installation. The package metadata did not declare that scope. The retry uses the supported default installer contract and leaves any Windows approval prompt visible to the founder. Permanent prevention is registered as `REG-20260811-1074-FSC02D-GCLOUD-WINGET-USER-SCOPE-NOT-APPLICABLE`.

# FSC02D winget interactive install not founder-visible — 2026-08-11

The default-scope `winget install --interactive` ran inside the tool-hosted shell, but no installer window became visible to the founder and the command timed out after 64 seconds. Installation therefore remains unqualified until package and executable checks pass. The corrected workflow uses silent installation for the non-credential SDK and a separately visible Windows terminal/browser only for founder-controlled authentication. Permanent prevention is registered as `REG-20260811-1075-FSC02D-WINGET-INTERACTIVE-INSTALL-NOT-FOUNDER-VISIBLE-TIMEOUT`.

# FSC02D saved gcloud authentication requires founder reauthentication — 2026-08-11

The isolated `moolsocial-dev-fsc02d` configuration was created and activated, and `hello@moolsocial.com` was selected. Setting the exact Dev project then required a token refresh, and non-interactive execution stopped because the saved Cloud SDK credential needs reauthentication. The project was not set. The next step is the official founder-visible `gcloud auth login` flow; Codex will not enter, capture, copy or echo credentials. Permanent prevention is registered as `REG-20260811-1076-FSC02D-GCLOUD-SAVED-AUTH-REAUTHENTICATION-REQUIRED`.

# FSC02D Firebase reprobe before visible reauthentication confirmation — 2026-08-11

The exact Dev Android app inventory was probed again while the founder-visible Firebase reauthentication process was still open and before founder confirmation. It reproduced the same generic failure and did not return project data. No further authenticated Firebase command may run until the founder confirms the official flow succeeded or shares the current visible prompt. Permanent prevention is registered as `REG-20260811-1077-FSC02D-FIREBASE-REPROBE-BEFORE-VISIBLE-REAUTH-CONFIRMATION`.

# FSC02D default-browser Firebase URL launch policy block — 2026-08-11

The founder-requested exact Firebase Console URL was passed to `Start-Process` through the Windows default URL handler, but the desktop command policy rejected it before any tab opened. The retry resolves Chrome only through its registered Windows App Path and opens the bounded HTTPS project URL without interacting with any credential or security-code tab. Permanent prevention is registered as `REG-20260811-1078-FSC02D-DEFAULT-BROWSER-URL-START-PROCESS-POLICY-BLOCK`.

# FSC02D gcloud alpha Firebase help component permission block — 2026-08-11

A help-only probe for `gcloud alpha firebase extensions` discovered the optional alpha component was absent and gcloud attempted to offer installation. The system-wide SDK directory correctly denied that modification without elevation, and no component was installed. The workflow will use supported stable Firebase CLI and metadata controls; no elevation or alpha/beta component is required. Permanent prevention is registered as `REG-20260811-1079-FSC02D-GCLOUD-ALPHA-FIREBASE-HELP-COMPONENT-PERMISSION-BLOCK`.

# FSC02D ripgrep Windows wildcard evidence path — 2026-08-11

A read-only signing-fingerprint search passed `artifacts/quality/youtube-private-dev-*` as a positional ripgrep path. Windows did not expand the wildcard and ripgrep rejected it as an invalid filename. The retry uses the literal `artifacts/quality` root and ripgrep `--glob` filters. Permanent prevention is registered as `REG-20260811-1080-FSC02D-RIPGREP-WINDOWS-WILDCARD-DIRECTORY-PATH`.

# FSC02D optional ripgrep no-match exit not normalized — 2026-08-11

The corrected optional signing-fingerprint evidence search returned ripgrep exit 1 because no matching text existed, but the shell wrapper did not normalize that valid empty result and surfaced it as a failure. The workflow now derives the current signing fingerprint from the preserved installed OPPO package and compares it with Firebase registration. Permanent prevention is registered as `REG-20260811-1081-FSC02D-OPTIONAL-RIPGREP-NO-MATCH-EXIT-NOT-NORMALIZED`.

# FSC02D optional ripgrep no-match recurrence — 2026-08-11

The next optional `apksigner` owner search again allowed ripgrep exit 1 to propagate as a shell failure immediately after the prevention was registered. No device or file operation followed. Every further optional search must capture the exit code explicitly, accept 0 or 1, and throw only for 2 or higher before printing results. Permanent prevention is registered as `REG-20260811-1082-FSC02D-OPTIONAL-RIPGREP-NO-MATCH-RECURRENCE`.

# FSC02D empty App Check debug-token response false positive — 2026-08-11

An ad-hoc App Check inventory counted an empty REST result as one PowerShell item and incorrectly reported one registered debug token. Immediate raw-response reconciliation returned `{}`, and the founder-visible Firebase Console confirmed only Play Integrity is registered. No token was read, deleted or changed. Debug-token evidence must count only an explicitly present `debugTokens` array and cross-check the repository verifier before declaring a security issue. Permanent prevention is registered as `REG-20260811-1083-FSC02D-EMPTY-DEBUG-TOKEN-RESPONSE-FALSE-POSITIVE-COUNT`.

# FSC02D full verifier nested Firebase Extensions CLI auth failure — 2026-08-11

The full persistent `PublicDataReview` verifier passed its local stage and entered the nested cloud preflight, but the preflight still called the stale Firebase CLI session for `ext:list` and stopped at the empty Extensions inventory check. No cloud mutation ran. The corrected preflight will use the authenticated stable Firebase Extensions management API for this exact read-only inventory and remove the separate Firebase CLI login dependency. Permanent prevention is registered as `REG-20260811-1084-FSC02D-FULL-VERIFIER-NESTED-FIREBASE-EXTENSIONS-CLI-AUTH-FAILURE`.

# FSC02D PowerShell `$null` regex expansion in control test — 2026-08-11

The first local control test for clearing the short-lived Extensions access token used a double-quoted regex containing backslash-dollar-null. PowerShell expanded `$null` to an empty value and left an illegal trailing backslash, so the test stopped before cloud execution. The correction escapes a single-quoted literal through `[regex]::Escape`. Permanent prevention is registered as `REG-20260811-1085-FSC02D-POWERSHELL-NULL-REGEX-EXPANSION-IN-CONTROL-TEST`.

# FSC02D gcloud active-configuration informational stderr — 2026-08-11

The corrected full verifier entered its nested cloud preflight, but gcloud emitted “Your active configuration is: [moolsocial-dev-fsc02d]” on native stderr and Windows PowerShell promoted the informational line to a terminating `NativeCommandError`. No cloud mutation ran and no security mismatch was reported. The retry pins `CLOUDSDK_ACTIVE_CONFIG_NAME=moolsocial-dev-fsc02d` for the entire verifier process after confirming its exact account, project and region. Permanent prevention is registered as `REG-20260811-1086-FSC02D-GCLOUD-ACTIVE-CONFIG-INFORMATIONAL-STDERR-NESTED-FAILURE`.

# FSC02D gcloud config get-value informational stderr recurrence — 2026-08-11

The direct cloud preflight still stopped at `gcloud config get-value account` because that subcommand itself emits the active-configuration notice on native stderr, even with the exact configuration pinned. No cloud mutation ran. The correction replaces this identity lookup with `gcloud auth list --filter=status:ACTIVE`, requires the exact authorized account and removes `config get-value` from strict nested Windows PowerShell gates. Permanent prevention is registered as `REG-20260811-1087-FSC02D-GCLOUD-CONFIG-GET-VALUE-STDERR-RECURRENCE`.

# FSC02D PowerShell 7 standard-path assumption — 2026-08-11

The first local deployment-control rerun invoked PowerShell 7 from the conventional `C:\Program Files\PowerShell\7\pwsh.exe` path, but this host exposes PowerShell 7.6.4 through its WindowsApps package path, so the test did not start. No cloud or device action ran. The corrected workflow resolves `pwsh` with `Get-Command` and invokes the exact discovered executable. Permanent prevention is registered as `REG-20260811-1088-FSC02D-POWERSHELL7-STANDARD-PATH-ASSUMPTION`.

# FSC02D transient Firebase debug-log evidence pointer — 2026-08-11

The permanent regression-memory gate rejected the two Firebase CLI failure entries because their evidence arrays still required the transient `firebase-debug.log`, while the durable quality record already preserved the sanitized facts. The transient pointer was removed from both entries; no log contents or credentials were read. Permanent prevention is registered as `REG-20260811-1089-FSC02D-TRANSIENT-FIREBASE-DEBUG-LOG-EVIDENCE-POINTER`.

# FSC02D exec JavaScript composition syntax error — 2026-08-11

A read-only focused-test evidence search was wrapped in malformed compact JavaScript, so execution stopped before PowerShell or ripgrep ran. No repository, cloud, build or device state changed. The corrected workflow retains the qualified multiline orchestration form. Permanent prevention is registered as `REG-20260811-1090-FSC02D-EXEC-JAVASCRIPT-COMPOSITION-SYNTAX-ERROR`.

# FSC02D ripgrep Windows wildcard-path recurrence — 2026-08-11

A focused-test evidence search passed wildcard-bearing Windows paths to ripgrep and repeated the already registered invalid-path failure. No test, build, cloud or device action ran. The corrected search uses literal `docs/quality` and `config` roots plus filename `--glob` filters. Permanent prevention is registered as `REG-20260811-1091-FSC02D-RIPGREP-WINDOWS-WILDCARD-PATH-RECURRENCE`.

# FSC02D unsupported delivery-disposition vocabulary — 2026-08-11

The approved UI locks passed, but the delivery discipline gate rejected the ticket assessment because `verification` and `conditional_external_write` are not implementation-disposition enum values. The ticket is truthfully represented by the existing `reuse`, `configuration` and `test_only_acceptance` values; conditional Dev authority remains separately constrained by dependencies and execution fields. Permanent prevention is registered as `REG-20260811-1092-FSC02D-UNSUPPORTED-DELIVERY-DISPOSITION-VOCABULARY`.

# FSC02D apply-patch multiline-context mismatch — 2026-08-11

The first enum correction patch inferred multiline JSON formatting from converted output, but the source file stores the disposition array on one line, so the patch was rejected atomically. No file changed. The retry uses the exact inspected literal source line. Permanent prevention is registered as `REG-20260811-1093-FSC02D-APPLY-PATCH-MULTILINE-CONTEXT-MISMATCH`.

# FSC02D ripgrep Gradle wildcard-path second recurrence — 2026-08-11

The Android metadata probe truthfully found no `google-services.json`, but its following Gradle search again passed wildcard-bearing Windows paths to ripgrep and was rejected. No source, build, cloud or device state changed. Remaining searches use literal roots and filename `--glob` filters only. Permanent prevention is registered as `REG-20260811-1094-FSC02D-RIPGREP-GRADLE-WILDCARD-PATH-SECOND-RECURRENCE`.

# FSC02D Firebase getConfig static-assertion layout assumption — 2026-08-11

The first YouTube public Dev build-control test expected the entire Firebase Android `getConfig` route as one contiguous source literal, while the wrapper composes its fixed service prefix and encoded resource suffix across two expressions. No build, cloud mutation or device action ran. The corrected test proves both immutable parts independently. Permanent prevention is registered as `REG-20260811-1095-FSC02D-FIREBASE-GETCONFIG-STATIC-ASSERTION-LAYOUT-ASSUMPTION`.

# C29A MVP scope gate omits test-and-gate authority — 2026-08-11

C29A's delivery lock passed, but the scope gate treated the host-only ticket as closed because its execution calculation did not include the declared `testOrGateWriteAuthorized` field. No build, cloud or device action ran. The gate now recognizes that exact field while C29A keeps runtime, backend, build, install and external writes false. Permanent prevention is registered as `REG-20260811-1096-C29A-MVP-SCOPE-GATE-OMITS-TEST-AND-GATE-AUTHORITY`.

# C29A accepted platform-configuration test lock mutation — 2026-08-11

Host cycle 1 stopped at the approved UI lock because the earlier build-boundary change edited accepted production file `apps/mobile/test/platform_configuration_test.dart`. No subsequent cycle step, build, cloud write or device action ran. The file was restored byte-for-byte, the accepted runtime message substring was retained, and the new condition remains asserted only by the dedicated C29A control test. Permanent prevention is registered as `REG-20260811-1097-C29A-ACCEPTED-PLATFORM-CONFIGURATION-TEST-LOCK-MUTATION`.

# C29B PowerShell foreach-pipe parser error — 2026-08-11

The first Java-process CPU diagnostic placed a formatting pipe directly after a compact `foreach` statement, and PowerShell rejected it as an empty pipe element before sampling. No process, build, file, cloud or device state changed. The corrected command collects loop output into an array before formatting. Permanent prevention is registered as `REG-20260811-1098-C29B-POWERSHELL-FOREACH-PIPE-PARSER-ERROR`.

# C29B Firebase Android client-key restriction mismatch — 2026-08-11

The no-value Firebase Android client-key metadata gate found that the auto-associated key did not match the required exact `com.moolsocial.app` plus installed signing SHA-1 application boundary. No key value was read or printed, and no cloud state changed. The build remains closed while only restriction metadata is diagnosed; any correction requires a separately bounded Dev security ticket. Permanent prevention is registered as `REG-20260811-1099-C29B-FIREBASE-ANDROID-CLIENT-KEY-RESTRICTION-MISMATCH`.

# C29B null allowedApplications type probe — 2026-08-11

The follow-up key-metadata diagnostic called `GetType()` on the absent/null `allowedApplications` property and stopped with `InvalidOperation`. No cloud state changed and no key value was read. Null now means zero qualified Android applications and blocks the APK build until the bounded Dev restriction is corrected. Permanent prevention is registered as `REG-20260811-1100-C29B-NULL-ALLOWED-APPLICATIONS-TYPE-PROBE`.

# Regression-memory stale script name — 2026-08-11

The post-registration gate invoked the nonexistent shorthand `scripts/check-regression-memory.ps1` and stopped before reading repository state. No cloud, build or device action ran. The exact discovered repository script `scripts/check-codex-development-regression-memory.ps1` is now required. Permanent prevention is registered as `REG-20260811-1101-REGRESSION-MEMORY-STALE-SCRIPT-NAME`.

# FSC02E ripgrep Windows wildcard-path third recurrence — 2026-08-11

The FSC02E gate-discovery read used `scripts/check-mvp*.ps1` as a path operand, and Windows rejected that wildcard-bearing literal before ripgrep could search. The scope JSON had parsed, but no gate, cloud or device action ran. All later filename filtering uses a literal directory root with ripgrep `--glob`. Permanent prevention is registered as `REG-20260811-1102-FSC02E-RIPGREP-WINDOWS-WILDCARD-PATH-THIRD-RECURRENCE`.

# FSC02E PowerShell boolean-literal reporting error — 2026-08-11

The exact API-key restrictions patch, bounded operation poll and postwrite assertions completed, but the final summary object used `false` rather than PowerShell `$false`. Reporting stopped after the cloud mutation, so the mutation must not be retried. A separate no-value metadata GET establishes completion. Permanent prevention is registered as `REG-20260811-1103-FSC02E-POWERSHELL-BOOLEAN-LITERAL-REPORTING-ERROR`.

# C29B exec JavaScript TextDecoder assumption — 2026-08-11

The first full machine-state replacement helper attempted to use `TextDecoder`, which is unavailable in the isolated exec JavaScript runtime. It stopped before calling `apply_patch`, so `config/apk-regression-gate-state.json` retained the consumed C28F state and no build opened. The retry uses the ASCII-safe base64 string returned by `atob` and re-reads the target first. Permanent prevention is registered as `REG-20260811-1104-C29B-EXEC-JAVASCRIPT-TEXTDECODER-ASSUMPTION`.

# C29B exec JavaScript atob assumption — 2026-08-11

The second full machine-state helper substituted `atob`, which is also unavailable in the isolated exec JavaScript runtime. It stopped before `apply_patch`, leaving the old consumed C28F machine gate intact. The next retry eliminates decoding and reads the ASCII JSON directly through PowerShell `Get-Content -Raw`. Permanent prevention is registered as `REG-20260811-1105-C29B-EXEC-JAVASCRIPT-ATOB-ASSUMPTION`.

# C29B strict nonzero-Java-CPU final process guard — 2026-08-11

The final process guard treated any nonzero three-second CPU delta from an existing Java daemon as an active build and stopped before invoking the wrapper. No build or device action ran and one-build authority remains unconsumed. The corrected qualification combines command-line ownership, reserved-output absence and repeated bounded samples, while never killing a daemon merely to force zero CPU. Permanent prevention is registered as `REG-20260811-1106-C29B-STRICT-NONZERO-JAVA-CPU-FINAL-PROCESS-GUARD`.

# C29B wrapper isolated-gcloud active-account rejection — 2026-08-11

The sole C29B wrapper invocation stopped at `build-buy-device-review.ps1`'s active-account check before Firebase configuration retrieval and before Flutter was invoked. No APK or provenance output exists and OPPO r60.28 remains untouched. The sealed one-build authority is consumed and the same wrapper invocation must not be retried. A new successor requires exact PowerShell 7 child-process gcloud diagnosis, wrapper correction if required and fresh host qualification. Permanent prevention is registered as `REG-20260811-1107-C29B-WRAPPER-ISOLATED-GCLOUD-ACTIVE-ACCOUNT-REJECTION`.

# C29C multiple Get-Command gcloud resolution — 2026-08-11

The first C29C executable preflight asked `Get-Command` for both `Application` and `ExternalScript`, receiving `gcloud.ps1`, `gcloud.cmd` and `gcloud`. Casting that collection concatenated all paths into an invalid command. No gcloud subcommand, token request, cloud write, build or device action ran. The context gate now uses PowerShell's normal single highest-precedence resolution. Permanent prevention is registered as `REG-20260811-1108-C29C-MULTIPLE-GET-COMMAND-GCLOUD-RESOLUTION`.

# C29C cross-process PSObject JSON harness — 2026-08-11

The corrected context gate returned a PowerShell object, but the parent harness tried to parse PowerShell's cross-process display formatting as JSON. The gate had requested no token and performed no write. Fresh-child qualification now runs `ConvertTo-Json` inside the child process so only structured JSON crosses the boundary. Permanent prevention is registered as `REG-20260811-1109-C29C-CROSS-PROCESS-PSOBJECT-JSON-HARNESS`.

# C29C backend verify wrong workdir and external npm log — 2026-08-11

Host cycle 1 launched `npm run verify` from the repository root instead of `backend/functions`, stopped with ENOENT, and npm automatically wrote its failure log under the user npm cache outside the authorized workspace. That log will not be read, copied or mutated. No later test, cloud, APK or device action ran. The retry enters the exact backend directory and redirects `NPM_CONFIG_CACHE` into C29C's repository evidence folder. Permanent prevention is registered as `REG-20260811-1110-C29C-BACKEND-VERIFY-WRONG-WORKDIR-EXTERNAL-NPM-LOG`.

# C29C YouTube capability-registry default revision mismatch — 2026-08-11

Host cycle 1 passed backend 471, Flutter 82/analysis, both Android player compiles and local provider/build controls, then the official capability verifier rejected the governed historical revision pins against the current official revisions (Data `20260810`, Analytics/Reporting `20260809`). The verifier intentionally exposes no bypass arguments. No registry, cloud, APK or device state changed. C29C pauses for a separate reconciliation ticket that may update revision fields only after exact method/classification invariance is proved. Permanent prevention is registered as `REG-20260811-1111-C29C-YOUTUBE-CAPABILITY-REGISTRY-DEFAULT-REVISION-MISMATCH`.

# FSC02F large registry patch read truncation — 2026-08-11

The first revision-only patch helper attempted to round-trip the full capability registry through shell tool output. The output boundary truncated the file, so the helper refused to mutate when it could not see all 102 qualified occurrences. The bounded retry performs exact-count replacements inside one filesystem process, preserves UTF-8 without BOM and immediately verifies JSON and semantic invariance. Permanent prevention is registered as `REG-20260811-1112-FSC02F-LARGE-REGISTRY-PATCH-READ-TRUNCATION`.

# C29C redirected cycle gate owner not surfaced — 2026-08-11

Fresh host cycle 1 exited nonzero after 196 seconds, but its redirected harness did not label and immediately check every later PowerShell gate, so the terminal result contained no failing owner. No cycle was counted and no cloud, APK or device action was authorized. Ticket-scoped logs are inspected only after this registration; the retry uses an explicit named-step wrapper that emits the failing owner and log tail. Permanent prevention is registered as `REG-20260811-1113-C29C-REDIRECTED-CYCLE-GATE-OWNER-NOT-SURFACED`.

# C29C official Discovery nondeterministic revision — 2026-08-11

The diagnosed fresh-cycle failure was the public YouTube Data Discovery endpoint returning revision `20260806` minutes after FSC02F observed and pinned `20260810`; both responses exposed the same complete 83/83 method inventory. Analytics and Reporting remained `20260809`. No registry rewrite was retried. The external revision marker must be sampled and any verifier-policy successor must preserve exact method/scope/HTTP/classification drift detection rather than chasing one cache value. Permanent prevention is registered as `REG-20260811-1114-C29C-OFFICIAL-DISCOVERY-NONDETERMINISTIC-REVISION`.

# FSC02G compacted exec-cell receipt loss — 2026-08-11

The FSC02G multi-step verification command produced and preserved three successful live-verifier logs, but its ephemeral exec-cell completion receipt was unavailable after context compaction. The three successful network rounds are not repeated. Remaining local gates use a repository-local named-step receipt so each exit result and the final aggregate result survive orchestration compaction. Permanent prevention is registered as `REG-20260811-1115-FSC02G-COMPACTED-EXEC-CELL-RECEIPT-LOSS`.

# FSC02G MVP scope-state filename assumption — 2026-08-11

The FSC02G status probe inferred a nonexistent `config/mvp-scope-governance-state.json` path and produced a read-only path-not-found error. `rg --files` established the exact owner as `config/mvp-scope-gate-state.json`; every later scope-state read and write uses that discovered path. Permanent prevention is registered as `REG-20260811-1116-FSC02G-MVP-SCOPE-STATE-FILENAME-ASSUMPTION`.

# FSC02G regression append context-format mismatch — 2026-08-11

The first regression-registry append patch assumed pretty-printed multiline arrays from converted display output, while the source tail uses compact arrays. `apply_patch` rejected the edit atomically. The retry uses the exact inspected source tail and keeps all prior entries intact. Permanent prevention is registered as `REG-20260811-1117-FSC02G-REGRESSION-APPEND-CONTEXT-FORMAT-MISMATCH`.

# C29C source manifest omitted official verifier — 2026-08-11

The prior C29C source aggregate included the official capability registry but omitted `scripts/verify-youtube-official-api-capability-registry.mjs`, even though every host cycle executes it and FSC02G changed it. Before either qualifying cycle is counted, the new immutable aggregate includes both owners and validates all 26 hashes before and after each cycle. Permanent prevention is registered as `REG-20260811-1118-C29C-SOURCE-MANIFEST-OMITTED-OFFICIAL-VERIFIER`.

# C29C scope-restore multi-context patch mismatch — 2026-08-11

The first C29C scope-restore patch combined many distant replacements and assumed stale compact-array formatting. `apply_patch` rejected the edit atomically when the exact current state differed. The retry reads the latest literal source and applies bounded exact-context state transitions. Permanent prevention is registered as `REG-20260811-1119-C29C-SCOPE-RESTORE-MULTI-CONTEXT-PATCH-MISMATCH`.

# C29C scope-restore second overlong-context mismatch — 2026-08-11

The second C29C scope-restore attempt still used one formatting-sensitive whole-object context and was rejected atomically. The corrected transition uses only short, bounded field replacements with immediate JSON and machine-gate validation. Permanent prevention is registered as `REG-20260811-1120-C29C-SCOPE-RESTORE-SECOND-OVERLONG-CONTEXT-MISMATCH`.

# C29C scope-restore mixed-hunk mismatch — 2026-08-11

A later scope-restore edit grouped unrelated exclusion, dependency and state hunks; one dependency hunk did not match and `apply_patch` rejected the complete mutation. Remaining changes are applied as independent, freshly inspected groups. Permanent prevention is registered as `REG-20260811-1121-C29C-SCOPE-RESTORE-MIXED-HUNK-MISMATCH`.

# C29C default Node and Java PATH diagnostic — 2026-08-11

The command-availability probe invoked ambient PATH tools, found Node `24.14.1` rather than the previously qualified Node 22 runtime, and then stopped because Java was not on PATH. No test, source, cloud, build or device action occurred. Host cycles resolve and invoke the exact configured dependency and Android/Gradle runtimes by absolute path. Permanent prevention is registered as `REG-20260811-1122-C29C-DEFAULT-NODE-AND-JAVA-PATH-DIAGNOSTIC`.

# C29C ripgrep Windows wildcard-path recurrence — 2026-08-11

The Node-runtime evidence search again passed wildcard-bearing Windows directory operands to ripgrep, causing invalid-path errors. The separate package manifest read succeeded, but no qualification step ran. Every later search uses literal roots plus `--glob` filters. Permanent prevention is registered as `REG-20260811-1123-C29C-RIPGREP-WINDOWS-WILDCARD-PATH-RECURRENCE`.

# C29C ripgrep ignored npx node_modules — 2026-08-11

The bounded search for the repository-contained npx Node 22 executable returned no result because ripgrep honored ignore rules inside the cache's `node_modules` tree. No state changed. Searches inside this exact evidence cache use `rg --files -uu` or a literal bounded fallback. Permanent prevention is registered as `REG-20260811-1124-C29C-RIPGREP-IGNORED-NPX-NODE-MODULES`.

# C29C qualifying cycle 1 nonzero without terminal owner — 2026-08-11

Fresh C29C qualifying cycle 1 exited nonzero after 228 seconds, but the outer orchestration result did not surface the intended named owner or log tail. The attempt is uncounted, its step logs remain preserved, and no cloud, APK or device action was authorized. Diagnosis uses only those durable logs; a successor prefix must write a partial machine-readable receipt from a top-level catch. Permanent prevention is registered as `REG-20260811-1125-C29C-QUALIFYING-CYCLE-1-NONZERO-WITHOUT-TERMINAL-OWNER`.

# C29C fresh child gcloud absent from inherited PATH — 2026-08-11

The uncounted cycle passed Node `471/471`, Flutter `82/82`, analysis, both player compiles, local controls and the official `99/99` gate, then its fresh PowerShell child could not resolve `gcloud`. Google Cloud CLI was installed after the long-running Codex desktop process started, so the new SDK bin was not inherited. Successor cycles and the eventual bounded wrapper process prepend the exact installed SDK bin only to their process PATH; no system PATH, gcloud configuration, token or cloud state is changed. Permanent prevention is registered as `REG-20260811-1126-C29C-FRESH-CHILD-GCLOUD-NOT-ON-INHERITED-PATH`.

# C29C qualifying cycle A failed with partial receipt — 2026-08-11

The first successor cycle after bounded gcloud PATH remediation still exited nonzero after 230 seconds and is uncounted. No cloud, APK or device action was authorized. Its partial machine-readable receipt preserves the exact error and every completed named step for post-registration diagnosis; both complete qualification cycles must restart under new prefixes. Permanent prevention is registered as `REG-20260811-1127-C29C-QUALIFYING-CYCLE-A-FAILED-WITH-PARTIAL-RECEIPT`.

# C29C global-navigation unrelated RequireImplemented flag — 2026-08-11

The uncounted cycle passed backend, Flutter, both player compiles, YouTube controls, official `99/99` verification and exact fresh gcloud context, then the reconstructed harness invoked the accepted global-navigation gate with `-RequireImplemented`. That optional portfolio-wide flag rejected unrelated incomplete C23 Home-hub owners that C29C neither owns nor changes. C29C uses the accepted contract without that flag and retains focused Social/Shop and exported-semantics checks. Permanent prevention is registered as `REG-20260811-1128-C29C-GLOBAL-NAVIGATION-UNRELATED-REQUIRE-IMPLEMENTED-FLAG`.

# C29D external PowerShell RuntimeDefine array binding — 2026-08-11

The first structural C29D machine-gate call passed scope, build controls and permanent regression memory, then its external `pwsh -File` boundary treated the second `-RuntimeDefine` array item as positional. No wrapper invocation, Firebase configuration retrieval, Flutter build, APK or device action occurred. The retry invokes the gate in-process so the typed array binds exactly. Permanent prevention is registered as `REG-20260811-1129-C29D-EXTERNAL-POWERSHELL-RUNTIMEDEFINE-ARRAY-BINDING`.

# C29D uiautomator /dev/tty no XML — 2026-08-11

The first authorized r60.30 launch succeeded, but this OPPO's Android 13 `uiautomator dump /dev/tty` returned no XML, stopping the capture sequence before the screenshot. The app was not reinstalled, cleared or downgraded. The retry uses a ticket-scoped `/sdcard/Download` hierarchy file and pulls it into repository evidence. Permanent prevention is registered as `REG-20260811-1130-C29D-UIAUTOMATOR-DEV-TTY-NO-XML`.

# C29D PowerShell reserved PID variable — 2026-08-11

The first bounded app-log probe assigned the package process id to `$pid`, which collides case-insensitively with PowerShell's read-only automatic `$PID`. It stopped before logcat capture or evidence persistence. The retry uses `$moolAppProcessId` and keeps credential redaction ahead of persistence. Permanent prevention is registered as `REG-20260811-1131-C29D-POWERSHELL-RESERVED-PID-VARIABLE`.

# C29D ripgrep nonexistent Social feature root — 2026-08-11

A read-only player-state source search included the inferred path `apps/mobile/lib/features/social`, which does not exist, and ripgrep therefore returned nonzero after excessive output from the valid YouTube core root. No app, device, cloud or source runtime state changed. Later inspection first resolves exact owners with `rg --files` and searches only literal existing files with narrow terms. Permanent prevention is registered as `REG-20260811-1132-C29D-RIPGREP-NONEXISTENT-SOCIAL-FEATURE-ROOT`.

# C29D PowerShell nested-quote XML probe — 2026-08-11

A read-only text/content-description extraction embedded a double-quoted regular expression inside the PowerShell command string and failed at parse time before reading the captured hierarchy. No app, device, cloud or evidence state changed. Later probes use literal single-quoted patterns or PowerShell XML parsing with exact file operands. Permanent prevention is registered as `REG-20260811-1133-C29D-POWERSHELL-NESTED-QUOTE-XML-PROBE`.

# C29D C29C evidence Node executable not present — 2026-08-11

A read-only search for `node.exe` under the preserved C29C evidence root returned no match because that root retains qualification receipts and caches but not an executable at the inferred location. No runtime or repository state changed. Later diagnostics read the exact runtime path from a preserved receipt or use built-in PowerShell/.NET without broadening filesystem scope. Permanent prevention is registered as `REG-20260811-1134-C29D-C29C-EVIDENCE-NODE-EXECUTABLE-NOT-PRESENT`.

# C29E computer-use skill resource missing — 2026-08-11

The required Windows-control skill could not be read from the exact versioned `SKILL.md` path advertised by the available-skills catalog because that host path is absent. No plugin was installed or replaced and no screenshot, app, device or repository state changed. The skill is reported unavailable and the bounded fallback uses only founder-authorized read-only ADB screenshot inventory plus local image inspection within MoolSocial scope. Permanent prevention is registered as `REG-20260811-1135-C29E-COMPUTER-USE-SKILL-RESOURCE-MISSING`.

# C29E ripgrep inferred backend roots missing — 2026-08-11

The YouTube owner inventory passed inferred top-level `services` and `functions` roots that do not exist, so ripgrep returned nonzero after printing matches from valid app and deployment roots. No file or runtime state changed. Later reuse audits resolve owners from the exact repository-root file list and inspect only verified literal paths. Permanent prevention is registered as `REG-20260811-1136-C29E-RIPGREP-INFERRED-BACKEND-ROOTS-MISSING`.

# C29E scope transition overlong mixed-patch mismatch — 2026-08-11

The first C29E scope transition grouped the selection assessment, ticket, authority and protected-candidate replacements into one overlong patch. One copied test-plan line differed from current state and `apply_patch` rejected the complete mutation atomically. The corrected transition uses small freshly inspected blocks and validates JSON plus the selected-ticket manifest hash. Permanent prevention is registered as `REG-20260811-1137-C29E-SCOPE-TRANSITION-OVERLONG-MIXED-PATCH-MISMATCH`.

# C29E scope ticket-array group mismatch — 2026-08-11

The next transition still grouped four ticket arrays with later authority blocks, and `apply_patch` rejected the compound verification context. No scope-state bytes changed in that attempt. The corrected edit isolates each array and each disclosure, authority and protected-state field with the shortest current context. Permanent prevention is registered as `REG-20260811-1138-C29E-SCOPE-TICKET-ARRAY-GROUP-MISMATCH`.

# C29E scope test-plan stale-line recurrence — 2026-08-11

The isolated test-plan patch repeated the stale APK evidence string from the earlier rejected compound edit rather than the current `badging_version_and_source_audit` line. It was rejected before mutation. Every rejected hunk is now re-read and copied exactly before retry. Permanent prevention is registered as `REG-20260811-1139-C29E-SCOPE-TEST-PLAN-STALE-LINE-RECURRENCE`.

# C29E regression gate unsupported runtime phase — 2026-08-11

The first C29E regression-memory call used `-Phase runtime`, but the gate accepts only `general`, `implementation`, `build` or `device`; parameter validation stopped before execution. The source ticket uses `implementation`, while later build/device phases remain closed until separately authorized. Permanent prevention is registered as `REG-20260811-1140-C29E-REGRESSION-GATE-UNSUPPORTED-RUNTIME-PHASE`.

# C29E regression gate unsupported TicketId parameter — 2026-08-11

The corrected call added `-TicketId`, but this gate declares only `Phase`, `BuildMode` and `RepositoryRoot`; binding stopped before gate execution. Later calls use only declared parameters and `-Phase implementation` for C29E source work. Permanent prevention is registered as `REG-20260811-1141-C29E-REGRESSION-GATE-UNSUPPORTED-TICKETID-PARAMETER`.

# C29E obsolete YouTube surface bar analyzer warning — 2026-08-11

The first focused Home-and-dock analyzer run found the private legacy navy `_YouTubeSurfaceBar` declaration unreachable after every call site moved to the new provider-owned YouTube Home and watch headers. No build, install, device, cloud or protected runtime state changed. The obsolete private declaration is removed only after confirming zero remaining references, then the same focused analyzer is rerun. Permanent prevention is registered as `REG-20260811-1142-C29E-OBSOLETE-YOUTUBE-SURFACE-BAR-ANALYZER-WARNING`.

# C29E Dart ternary pattern-match syntax — 2026-08-11

The first full-bleed Shorts analyzer run stopped at parse time because a nullable-thumbnail object-pattern `case` was placed directly inside a ternary false branch, which Dart does not accept in that expression position. No test, build, install, device, cloud or protected runtime action followed. The successor uses a conventional explicit null branch and immediately reruns formatting plus the same focused analyzer. Permanent prevention is registered as `REG-20260811-1143-C29E-DART-TERNARY-PATTERN-MATCH-SYNTAX`.

# C29E stale Shorts source-test range delimiter — 2026-08-11

The first focused full-bleed source-contract run still delimited the Shorts implementation at the removed `_openShortDiscussion` method, so its `indexOf` returned `-1` before the redesigned assertions executed. Runtime source analysis had already passed and no build, install, device, cloud or protected runtime state changed. The test now delimits at the next stable surviving video-eligibility method and continues to assert the obsolete MoolSocial Short actions stay absent. Permanent prevention is registered as `REG-20260811-1144-C29E-STALE-SHORTS-SOURCE-TEST-RANGE-DELIMITER`.

# C29E no shared Social reply owner match — 2026-08-11

A bounded reuse search across `SharedSession` and shared models returned no social comment or reply mutation owner and ripgrep exited nonzero. No runtime, build, device or cloud state changed. The C29E Feed renders the genuine stored publication owner but does not invent reply persistence; reply submission stays truthfully unavailable until a real owner and tests exist. Permanent prevention is registered as `REG-20260811-1145-C29E-NO-SHARED-SOCIAL-REPLY-OWNER-MATCH`.

# C29E stored post not projected in Feed — 2026-08-11

The first C29E creation suite stored a genuine MoolSocial post and navigated to Feed, but the customer-visible Feed still rendered only its ownership-branded empty state. The real `SharedSession.socialPublishedItems` state remained intact. C29E reconnects that state through the existing `SocialPublishedContentCardV2` presentation owner and retains the empty shell only when there are no eligible MoolSocial posts. Permanent prevention is registered as `REG-20260811-1146-C29E-STORED-POST-NOT-PROJECTED-IN-FEED`.

# C29E stale MoolSocial Reel Create expectation — 2026-08-11

A predecessor test continued to require the Reel tool inside Social Create after the founder separated MoolSocial-hosted text, image, carousel, image poll, quick poll and quiz creation from YouTube-owned Shorts distribution. The reusable workbench retains Reel as an opt-in for other owners, while `SocialUniversalV2` disables it and the corrected test asserts it is absent there. Permanent prevention is registered as `REG-20260811-1147-C29E-STALE-MOOLSOCIAL-REEL-CREATE-EXPECTATION`.

# C29E stale single-page catalogue assertion — 2026-08-11

The first bounded-pagination suite passed its new behavioral tests but one predecessor source assertion still required the removed `final eligible = page.items` single-page expression. The empty-vs-error contract now asserts the stable bounded collector and its unmodifiable empty return, while separate behavior tests own target, deduplication, page-limit and shortfall semantics. Permanent prevention is registered as `REG-20260811-1148-C29E-STALE-SINGLE-PAGE-CATALOGUE-ASSERTION`.

# C29E registry gates command labels are not repository paths — 2026-08-11

The first post-C29E permanent-regression gate rejected new entries whose `gates` arrays included descriptive command labels such as `flutter analyze`, `dart format` and `flutter test`. That field is validated as literal repository-relative paths. The entries now retain only the existing regression-memory script path; command results remain in execution output and prose evidence. Permanent prevention is registered as `REG-20260811-1149-C29E-REGISTRY-GATES-COMMAND-LABELS-NOT-PATHS`.

# C29E grouped legacy Social matrix timeout — 2026-08-11

A grouped four-file legacy Social matrix reached its 240-second outer timeout without the shell result preserving a terminal test owner. No source mutation followed from the incomplete run and no build, install, device, cloud or protected runtime state changed. Each file is now run independently with an expanded reporter and its own bounded timeout before any accepted combined manifest is attempted. Permanent prevention is registered as `REG-20260811-1150-C29E-GROUPED-LEGACY-SOCIAL-MATRIX-TIMEOUT`.

# C29E mixed named-process probe nonzero — 2026-08-11

A read-only `Get-Process dart,flutter` diagnostic returned nonzero because the optional `flutter` process name was absent, even though it printed one unrelated long-lived Dart process. No process was terminated or mutated. Optional process audits now enumerate first and filter by name, and an existing process is never stopped without exact test-runner ownership and authority. Permanent prevention is registered as `REG-20260811-1151-C29E-MIXED-NAMED-PROCESS-PROBE-NONZERO`.

# C29E Screen 04 predecessor conformance contracts — 2026-08-11

The first individual Screen 04 conformance run reported eleven failures while every compact-device fitment case passed. The failing blocks still assumed fresh Social opened on Shorts, Social used the shared four-choice ribbon, Reel belonged to MoolSocial Create, and MoolSocial overlay actions lived beside the YouTube Short. C29E migrates only those superseded presentation assertions while retaining durable route, Back, provider-fail-closed and fitment coverage and separately proving the custom Mool button reaches the accepted global navigator. Permanent prevention is registered as `REG-20260811-1152-C29E-SCREEN04-PREDECESSOR-CONFORMANCE-CONTRACTS`.

# C29E Mool navigation owner path miss — 2026-08-11

A bounded read used a logical `screen04` component namespace as the presumed filesystem path for `mool_global_navigation_v2.dart`, and `Get-Content` returned nonzero because that concrete path does not exist. No file, build, device, cloud or protected runtime state changed. Unproven source paths are now resolved with `rg --files` before any line-range read. Permanent prevention is registered as `REG-20260811-1153-C29E-MOOL-NAVIGATION-OWNER-PATH-MISS`.

# C29E rightmost Mool overlay off-screen — 2026-08-11

The first migrated Screen 04 run passed C29E Home/Shorts/Create/Feed presentation and all fourteen compact fitment cases, but four connected-navigation journeys failed because the accepted Mool menu retained its predecessor left-edge overlay alignment while the new dock places Mool at the right edge. Its fixed-width menu therefore extended beyond the viewport and family actions were unhittable. The shared navigator gains an opt-in end-aligned compact overlay mode used only by Social; every existing caller retains the accepted default. Permanent prevention is registered as `REG-20260811-1154-C29E-RIGHTMOST-MOOL-OVERLAY-OFFSCREEN`.

# C29E stale Chat key and route-settle assumption — 2026-08-11

After the end-aligned overlay correction made connected family routes hittable, the second Screen 04 run retained two predecessor test assumptions: a family-specific `social-global-chat` finder and an immediate successive-route owner check. The current accepted connected navigator key and each route's terminal lifecycle are re-resolved before retry; the genuine Chat callback and exact Social destination contracts remain mandatory. Permanent prevention is registered as `REG-20260811-1155-C29E-STALE-CHAT-KEY-AND-ROUTE-SETTLE-ASSUMPTION`.

# C29E Social catalogue default Shorts mismatch — 2026-08-11

The focused route diagnosis found that the Screen 04 consumer and local dock correctly open YouTube Home first, while the independent shared Mool action catalogue still listed Shorts first and labelled the Home owner as Videos. Connected-family default resolution therefore disagreed with the approved C29E model. The shared catalogue is reconciled to Home, Shorts, Create, Feed while preserving the existing truthful route owners. Permanent prevention is registered as `REG-20260811-1156-C29E-SOCIAL-CATALOGUE-DEFAULT-SHORTS-MISMATCH`.

# C29E center Create gateway versus direct workbench — 2026-08-11

The third Screen 04 migration run reached only one failure: an all-actions helper tapped the local center + and expected the MoolSocial workbench, while C29E intentionally opens the ownership gateway there. Direct `sub=create` still opens the real MoolSocial workbench and has separate passing coverage. The local + assertion now requires the gateway so YouTube distribution authorization cannot be bypassed. Permanent prevention is registered as `REG-20260811-1157-C29E-CENTER-CREATE-GATEWAY-VS-DIRECT-WORKBENCH`.

# C29E individual Feed ownership timeout — 2026-08-11

The individually bounded `social_v2_moolsocial_feed_ownership_test.dart` process produced no reporter output and reached its 300-second outer timeout. It is not grouped with any other file, no source conclusion is inferred from the missing terminal result, and no build, device, cloud or protected runtime state changed. The file is inspected and split by named test before any retry. Permanent prevention is registered as `REG-20260811-1158-C29E-INDIVIDUAL-FEED-OWNERSHIP-TIMEOUT`.

# C29E Mool tap direct-callback expectation — 2026-08-11

The first focused run after restoring common Chat retained an obsolete assertion that a simple Mool tap directly invoked `onOpenMool`. The accepted `MoolGlobalNavigationV2` correctly uses that tap to open the connected family navigator; actual destination navigation follows a family selection and is covered by the Screen 04 route suite. The focused test now requires the switcher overlay and no premature direct callback. Permanent prevention is registered as `REG-20260811-1159-C29E-MOOL-TAP-DIRECT-CALLBACK-EXPECTATION`.

# C29E stale YouTube Home Chat-absence assertion — 2026-08-11

The Screen 04 rerun after the founder confirmed Chat should remain on Social found one stale temporary assertion requiring `social-global-chat` to be absent on YouTube Home. The dock now exposes exactly one global Chat control outside the player. The corrected test opens Chat in one tap and uses system Back to require restoration of the exact provider-gated Home state. Permanent prevention is registered as `REG-20260811-1160-C29E-STALE-YOUTUBE-HOME-CHAT-ABSENCE-ASSERTION`.

# C29E stored Feed widget-test timeout — 2026-08-11

The Feed file was split by exact test name. Its static ownership contract passed immediately, while the isolated stored-publication widget test reached a 120-second timeout without a terminal reporter result. The investigation is now restricted to that test's direct `SharedSession.publishSocialContent` setup and lifecycle; the genuine stored-post projection requirement remains unchanged. Permanent prevention is registered as `REG-20260811-1161-C29E-STORED-FEED-WIDGET-TEST-TIMEOUT`.

# C29E Feed Retry ensureVisible not settled — 2026-08-11

The isolated loading/error/unavailable test rendered all three truthful Feed states, then attempted to tap Retry at y=593 on a 568-high test viewport. It awaited `ensureVisible` but did not settle the scroll animation before hit testing. The test now pumps to settlement before the tap and retains its retry-to-empty assertion. Permanent prevention is registered as `REG-20260811-1162-C29E-FEED-RETRY-ENSUREVISIBLE-NOT-SETTLED`.

# C29E continuous-batch Home-first and account keys — 2026-08-11

The first individual continuous Social batch passed eleven journeys and found two predecessor assumptions: fresh Social was expected to open Shorts, and YouTube Home was expected to expose the removed MoolSocial header profile key. C29E opens Home first and uses a provider-styled account affordance that reuses the same account owner. The tests now explicitly select Shorts where required and use the Home account key while retaining Creator workspace and Plans outcomes. Permanent prevention is registered as `REG-20260811-1163-C29E-CONTINUOUS-BATCH-HOME-FIRST-ACCOUNT-KEYS`.

# C29E account test mounted provider-gated Home — 2026-08-11

The continuous account-owner test changed to the YouTube Home account key but retained a fixture with public provider access disabled. That truthful provider-gated state returns before the available-catalogue Home header. The continuous account-owner test now enters through MoolSocial Feed's always-present profile affordance; the available-provider Home account control remains covered by the focused C29E fixture. Permanent prevention is registered as `REG-20260811-1164-C29E-ACCOUNT-TEST-MOUNTED-PROVIDER-GATED-HOME`.

# C29E protected Social inventory count change — 2026-08-11

The first post-C29E protected Social baseline gate stopped because the authorized current inventory contains 180 files while the predecessor baseline records 178. The gate did not silently rewrite its authority. The exact delta and the repository's founder-approved successor-baseline procedure are audited before any baseline mutation or retry. Permanent prevention is registered as `REG-20260811-1165-C29E-PROTECTED-SOCIAL-INVENTORY-COUNT-CHANGE`.

# C29E PowerShell wildcard ripgrep scope nonzero — 2026-08-11

A bounded discovery command listed C29 artifact directories successfully, then passed mixed wildcard path operands directly to ripgrep and returned nonzero without a protected-baseline match set. No repository, device, cloud or runtime state changed. Follow-up searches use proven parent directories plus include globs and explicit result filtering. Permanent prevention is registered as `REG-20260811-1166-C29E-POWERSHELL-WILDCARD-RG-SCOPE-NONZERO`.

# C29E named parity Reel and fresh-Shorts assumptions — 2026-08-11

The extra protected test batch passed every customer-copy, Work-route, Creator, plans, promotion and YouTube Connect case except two named-state assumptions: MoolSocial Create still required a Reel source, and fresh Social still expected Shorts. C29E removes MoolSocial-hosted Reel/Shorts and opens YouTube Home first. The parity matrix now covers the six approved MoolSocial formats and explicitly selects Shorts for its fail-closed state. Permanent prevention is registered as `REG-20260811-1167-C29E-NAMED-PARITY-REEL-AND-FRESH-SHORTS-ASSUMPTIONS`.

# C29E PowerShell r-alias hash diagnostic — 2026-08-11

A compact protected-tree recomputation named its relative-path helper `R`, which collided case-insensitively with PowerShell's `r` alias for `Invoke-History`. The pipeline emitted history errors and a false zero-file hash even though the shell exit was zero. That result is rejected. The recomputation uses a task-specific helper name and must independently prove the expected 180-file count before any seal records its hash. Permanent prevention is registered as `REG-20260811-1168-C29E-POWERSHELL-R-ALIAS-HASH-DIAGNOSTIC`.

# C29E obsolete C16B ticket gate not active — 2026-08-11

A historical C16B Social conformance script was selected by its broad filename during C29E acceptance. Its own guard correctly refused execution because the C16B selection/disclosure ticket is not the active sequential ticket. The gate is not forced or bypassed; C29E uses its active ticket, shared invariant, protected-baseline and focused Flutter contracts. Permanent prevention is registered as `REG-20260811-1169-C29E-OBSOLETE-C16B-TICKET-GATE-NOT-ACTIVE`.

# C29F aapt relative APK path rejection — 2026-08-11

The first read-only C29F artifact qualification passed a long repository-relative APK path to `aapt dump badging`. PowerShell had proved the file existed, but the native Android build-tools process rejected the relative asset path. The APK checksum remained exactly the wrapper-recorded value, no rebuild or install occurred, and build authority stayed consumed. All subsequent `aapt` and `apksigner` inputs are resolved absolute paths before invocation. Permanent prevention is registered as `REG-20260811-1170-C29F-AAPT-RELATIVE-APK-PATH-REJECTION`.

# C29F aapt long absolute path rejection — 2026-08-11

The second read-only C29F artifact qualification used the resolved absolute path, but `aapt` still rejected the existing APK because the deeply nested immutable evidence path exceeded the native tool's Windows path handling. The wrapper-recorded checksum remained unchanged and no rebuild or install occurred. The bounded successor maps the two existing artifact directories to unused temporary drive letters, inspects the checksum-bound files through those short paths, and removes both mappings in `finally`; it does not copy the APK. Permanent prevention is registered as `REG-20260811-1171-C29F-AAPT-LONG-ABSOLUTE-PATH-REJECTION`.

# C29F uiautomator `/dev/tty` returned no hierarchy — 2026-08-11

The first post-install runtime launch completed successfully, but the OPPO Android 13 `uiautomator dump /dev/tty` command returned no XML hierarchy for in-memory parsing. No app failure is inferred. The bounded successor writes one exact C29F temporary hierarchy file outside app storage, reads it immediately into memory, and removes only that verified temporary file; package data and installed identity remain untouched. Permanent prevention is registered as `REG-20260811-1172-C29F-UIAUTOMATOR-DEV-TTY-NO-HIERARCHY`.

# C29F PowerShell `$home` variable collision — 2026-08-11

The first Home-to-video runtime command assigned the parsed hierarchy to `$home`. PowerShell resolved that case-insensitively as the protected read-only `$HOME` variable and stopped before any video tap. The device had only returned to the already-qualified Home state; no app, install or data conclusion was affected. Runtime scripts now use task-specific variables such as `$c29fHomeXml` and never repurpose `$HOME` or `$home`. Permanent prevention is registered as `REG-20260811-1173-C29F-POWERSHELL-HOME-VARIABLE-COLLISION`.

# C29F Home video premature availability assumption — 2026-08-11

The corrected Home-to-video runtime command required a loaded video card from one immediate hierarchy after returning from Shorts. The real public provider was still in its truthful asynchronous loading/transition window, so no `Watch` card was present. No fabricated content or app failure is inferred. The successor uses bounded semantic polling, continues through the explicit loading state, and taps only a genuinely loaded card. Permanent prevention is registered as `REG-20260811-1174-C29F-HOME-VIDEO-PREMATURE-AVAILABILITY-ASSUMPTION`.

# C29F ADB pull substituted-drive destination rejection — 2026-08-11

The first native bounds evidence capture tried to pull the XML and PNG into a temporary `Q:` mapping of the long artifact directory. Android build-tools had accepted that mapping for reads, but ADB rejected the substituted-drive destination. The verified temporary device files were removed and no app data, APK or installed identity changed. ADB capture now runs with the exact artifact directory as its process working directory and uses short local filenames. Permanent prevention is registered as `REG-20260811-1175-C29F-ADB-PULL-SUBST-DESTINATION-REJECTION`.
