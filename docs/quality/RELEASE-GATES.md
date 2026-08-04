# Release gates

## Before every Android APK build

1. Register the exact candidate in
   `config/apk-regression-gate-state.json`, including branch, HEAD, unique
   version, build mode, source-manifest path/checksum/count and the exact
   non-secret runtime-define allowlist.
2. Mark every required pre-build regression `passed` only with an existing
   immutable evidence path. Record all post-build, install, cold-start,
   journey, lifecycle, accessibility, failure-scan, performance and founder
   gates as explicit pending/passed/failed machine states.
3. Run `scripts/check-windows-powershell-compatibility.ps1`. All mandatory
   PowerShell release gates must work under both current PowerShell and legacy
   Windows PowerShell 5.1. Modern-only .NET helpers such as
   `Path.GetRelativePath` and `Convert.ToHexString` are forbidden in gate
   scripts; a runtime/version mismatch is a release-gate defect, not an
   acceptable rerun instruction.
   The compatibility gate itself must pass when invoked from either host.
   Expected fail-closed protected-boundary stderr is classified by exit code
   and contract text; it must not become an unclassified terminating
   `NativeCommandError` merely because the invoking host is PowerShell 5.1.
   Resolve every piped evidence sink to an absolute path before invoking a
   script that may call `Push-Location`. When `Start-Process` launches helpers
   from this spaced workspace, explicitly quote each absolute argument; archived
   Dart helpers must also receive the exact mobile `.dart_tool/package_config.json`
   through `--packages` rather than relying on their archive directory.
4. Run `scripts/check-apk-regression-gate-state.ps1`. Any missing evidence,
   stale branch/HEAD/source identity, missing or additional runtime define,
   failed gate, reused candidate identity or unapproved build state rejects the
   build before Flutter starts.
4. Build Buy review APKs only through
   `scripts/build-buy-device-review.ps1`, which re-runs the machine gate. A
   passing pre-build gate authorizes one build, not installation,
   qualification, founder acceptance or promotion.
5. Preserve rejected APKs and their startup/log/checksum evidence. A candidate
   that remains on the native launch background, throws before `runApp`, or
   omits its sanctioned runtime mode is a failed APK even when source tests
   pass.

## Every pull request

1. Dart formatting, static analysis and unit/widget tests.
2. SQL Connect schema and generated-client validation.
3. Contract tests for touched operations.
4. No destructive production migration.
5. No generated secret or live Firebase configuration committed.
6. Accessibility semantics and minimum tap-target checks on touched UI.
7. Every touched user-facing screen has an approved-prototype comparison;
   current implementation goldens alone cannot approve visual or interaction
   conformance.
8. Customer-visible HTML and native UI pass the customer-copy boundary in
   `APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`: no review notes, prototype
   labels, internal planning terms, route/state/source language, implementation
   instructions or technical verbs presented as customer actions.
9. First-open changes preserve the locked boundary: consent and resolved
   current location before sign-in, then social-handle/OTP sign-in, then
   Universal. Permanent serviceable-area selection is available only from the
   user account after login.
10. First-open changes pass
    `FIRST-OPEN-REAL-USER-STATE-MATRIX.md`: older saved candidate data,
    app-switch/call/lock interruptions, process death, permission/settings
    returns and relaunches cannot bypass the currently required Screen 02.
11. First-open persistence proves that only explicit Screen 02 completion
    advances its completion version; unrelated saves preserve the prior
    version.
12. Screen 03 provider actions are never dead taps: each enabled provider opens
    its provider-controlled handoff or returns to a truthful MoolSocial-owned
    cancel, unavailable, offline or retry state. Review builds never fake a
    production provider success.
13. YouTube sign-in requests Google basic identity only. YouTube channel,
    upload, management and analytics scopes are prohibited during login.
14. Email/mobile OTP interruption, expiry, resend, change-method, process-death
    and duplicate-submit paths preserve Screen 02 area state and cannot mark a
    session ready without authoritative verification.
15. Customer-copy testing is state-complete, not default-screen-only. The
    touched checkpoint mounts every reachable loading, slow, resolved, denied,
    unavailable, failure, retry, provider-return, email/mobile OTP, wrong-code,
    resend and change-method state listed in
    `CUSTOMER-COPY-MACHINE-GATE.md`; it collects rendered text, field
    labels/hints and semantic labels and rejects implementation-relative copy
    such as `same screen`, `instead of email/mobile`, `example`, `demo`,
    `sample`, `for review` and `for testing`.
16. Screens 01–03 pass the supported-phone fitment matrix at compact and large
    Android/iOS logical viewports and at the required accessibility text scale.
    A pass means no Flutter overflow/exception, no clipped primary action, and
    every required action remains reachable and at least 44 logical pixels.
17. Physical-device mobile OTP is tested independently from email OTP after an
    ADB transport reset. The exact review APK must retain a verified,
    device-reachable Auth route without depending only on volatile
    `adb reverse` state. A reachable laptop service plus a failed phone route
    is a review-routing failure and must never be presented as proof that the
    customer is offline.
18. Social/external-media changes comply with
    `docs/delivery/SOCIAL-EXTERNAL-REACH-AND-CREATOR-STUDIO-FULL-STACK-CONTRACT.md`. No
    WebView renders MoolSocial UI; only the direct official YouTube provider
    player may use the narrow OS WebView/WKWebView exception.
19. Creator publishing chooses a destination before upload or uses the
    validated Standard Publish preset. Every selected destination passes its
    live capability rules and receives an explicit preview and consent.
20. Provider connections are separate from sign-in, least-privilege and name
    the exact eligible channel, Professional account, Page or business sender.
    Provider secrets and refresh tokens never enter client code or logs.
21. Distribution tests prove idempotency, unknown-outcome reconciliation,
    token revocation, quota/rate limits, cost stops and partial success without
    deleting successful external publications.
22. YouTube Social acceptance cannot be based on one hard-coded video. Evidence
    proves paginated native browsing from multiple supported source types,
    selection of multiple distinct eligible videos and replacement/release of
    the single active official player without leaving MoolSocial.
23. Buy work starts only after both `scripts/check-approved-ui-locks.ps1` and
    `scripts/check-social-protected-baseline.ps1` pass. A Buy change must not
    rebaseline Social, YouTube, Screens 01–03 or their accepted HTML packages.
24. A new Buy HTML/UI-UX candidate is reviewed and receives explicit founder
    `FINAL` before any native Flutter Buy implementation. The accepted package
    receives a new immutable checksum version; an earlier HTML file or
    reference is never overwritten.
25. Consumer Buy and verified Business Buy may share canonical product and pack
    identity, but their offers remain context-specific. Consumer UI cannot
    expose wholesale MOQ, trade credit or tax/freight terms, and Business UI
    cannot silently reuse consumer totals as landed wholesale price.
26. Every app change passes `scripts/check-brand-integrity.ps1 -Surface App`.
    The exact `MoolSocial` wordmark, navy/saffron/white/green identity, ordered
    tricolour line and two-by-two-grid Mool launcher are mandatory. A module
    cannot introduce a custom M, initial tile, placeholder circle or
    module-specific logo.
27. After the founder-approved R40.3 native Buy motion baseline, every task runs
    `scripts/check-buy-protected-baseline.ps1`. Test and documentation
    hardening may advance without changing its runtime tree. Any Buy runtime,
    presentation, routing or protected media change requires explicit founder
    approval and a new additive baseline; the existing R35.1, R38 and R40.3
    baselines are never overwritten. Logo motion and route-continuity changes
    are outside R40.3 and require a new checksum-matched candidate and founder
    review.
28. Until an approved Buy transport and authorization contract exists, every
    task runs `scripts/check-buy-backend-contract-boundary.ps1`. Protected Buy
    V2 production code cannot introduce a direct network/database client,
    WebView, URL-launcher commerce path, unapproved endpoint, review/mock/fake
    gateway or fabricated delayed completion. Backend and contract trees
    cannot acquire a Buy owner until identity, authorization, request/response
    and failure semantics are explicitly approved and recorded.
29. Until Buy data classification, consent, redaction, retention and
    observability contracts are approved, every task runs
    `scripts/check-buy-data-egress-boundary.ps1`. Native Buy V2 cannot directly
    send customer, order, address, prescription, payment or query state to
    logs, analytics, crash-report details, arbitrary clipboard/system-share
    channels or unapproved local stores, and cannot embed credential-like
    material. The established first-party address-request URL is the sole
    current clipboard allowlist entry.
30. The 2 August 2026 cumulative R55.4 OPPO review founder-approved only the
    scoped R43/DES-001, R45, R46, R47, R48, R52.1, R53, R54 and R55 owners.
    R51 FIX16 remains not approved and open for later enhancement. A future
    ticket must preserve every approved owner through its focused contracts,
    two complete Buy regressions and all protected gates; it cannot relabel the
    full cumulative R55.4 tree as approved or alter an accepted owner
    incidentally. The authoritative decision is
    `artifacts/quality/buy-motion-founder-decisions-20260802-88`.
31. Every pending or future Buy runtime ticket must pass a prewrite premium-
    motion applicability audit against
    `config/buy-premium-motion-policy.json` and
    `docs/quality/BUY-PREMIUM-MOTION-SURFACE-COVERAGE-20260802.md`. It records
    which requested effects are reused, newly applied, dependency-held or
    inapplicable. No ticket may fabricate loading/liveness/business state,
    add a perpetual decorative loop, move semantic/hit ownership, bypass
    reduced motion or create a duplicate owner merely to display an effect.
    The mandatory APK pre-build machine invokes
    `scripts/check-buy-premium-motion-policy-state.ps1` and fails closed when
    the candidate state omits the canonical policy, coverage/contract/
    disposition evidence, any of the four effect-disposition categories or an
    enabled required rule. `scripts/test-buy-premium-motion-policy-state.ps1`
    is the deterministic positive/negative self-test.

## Buy module trial sequence

The immutable Buy HTML authority is
`approved-references/screens/09-buy-complete/v1`, founder FINAL on
29 July 2026. It cannot be edited or replaced in place. The sequence below
starts native implementation from that checksum-backed reference; passing a
Flutter test or golden never replaces it as approval authority.

1. Preserve the accepted HTML packages, current protected Social source tree,
   exact OPPO-installed trial APK and current Dev provider boundary in the
   traceable baseline.
2. Approve the unified Buy operating model and prepare the complete Buy HTML
   candidate without editing Flutter.
3. Receive explicit founder `FINAL`, freeze a new immutable Buy reference and
   verify its interaction contract.
4. Implement native Flutter from that exact reference; do not embed the HTML
   prototype or substitute screenshots for production UI.
5. Pass formatting, analysis, full Flutter tests, operational goldens,
   Android/iOS builds, Functions verification and the complete Social plus Buy
   regression suite, including the brand-integrity gate.
6. Install the exact built APK on the connected OPPO and replay clean,
   retained-data, interruption, Personal Buy and Business Buy journeys.
7. Only then create a separately identified Dev deployment trial from the same
   committed source. Record source commit, APK SHA-256, installed APK SHA-256,
   backend revision/hash and rollback boundary.

## Every staging promotion

1. Build from a tagged commit, never from an uncommitted laptop state.
2. Deploy schema/connectors before clients only when backward-compatible.
3. Use `COMPATIBLE` schema validation after production contains data.
4. Run the clean-state journey replay on the emulator and staging.
5. Produce Android and iOS artifacts from the same source commit.
6. Upload Android to App Distribution and iOS to TestFlight.
7. Run Flutter integration tests on the Android and iOS device matrix.
8. Verify Crashlytics, Performance and business-intent events by platform.
9. Founder-approved screenwise visual and tap-path evidence is attached for
   every journey changed by `UI-CONFORMANCE-001`.
10. While `UI-CONFORMANCE-001` is open, no partial UI remediation is promoted
    to `main`; review occurs from the isolated complete candidate branch.
11. The attached founder evidence shows only finished customer language inside
    each simulated or native phone viewport. Technical annotations remain
    outside that viewport.
12. First-open evidence includes retained-data and interruption replays on the
    connected physical phone. A clean-install screenshot alone is rejected.
13. Before founder review, the connected phone is left at the current
    incomplete Screen 02 rather than at sign-in or Universal.
14. Physical-device evidence records and matches the reviewed APK and installed
    APK SHA-256 checksums. An Android Studio/VS Code run, hot reload or
    unidentified installed build is rejected as release evidence.
15. Founder handoff never terminates on an unapproved legacy downstream screen.
    Unavoidable connected screens are accepted as one checkpoint; for the
    first-open journey, Screen 02 and Screen 03 are a combined checkpoint.
16. Internal iteration and regression discovery are completed before founder
    handoff. The founder is not used as a repeated substitute for connected
    journey testing.
17. Every founder review link is verified against the loaded browser pathname,
    visible screen heading and expected primary content before handoff. An
    exact-screen request must open that exact screen directly; an upstream
    journey screen is not an acceptable substitute.
18. If browser control cannot verify the active page, the handoff explicitly
    states that the screen was not opened. It must not claim or imply that the
    requested review page is visible.
19. Customer-copy evidence names every state that was rendered. Evidence from
    only the initial/default state is rejected.
20. Android/iOS fitment evidence includes the smallest supported logical
    viewport, representative current phones, a large phone and accessibility
    text scaling. Physical Android evidence supplements but does not replace
    the cross-platform widget matrix.
21. Flutter production fitment is verified separately from HTML approval. The
    native matrix covers the approved phone viewports at 100% and 140% text,
    supported accessibility scaling above 140%, portrait/landscape, safe-area
    and cutout insets, keyboard/IME, display zoom, gesture/three-button
    navigation, interruption/resume, tablets, split-window resizing and
    foldable cover/unfolded/hinge states. Provider players retain minimum usable
    size, unobscured controls and correct fullscreen/orientation behavior. A
    founder-approved support boundary is required for any excluded device
    class; HTML screenshots alone never satisfy this gate.
22. The staged app artifact passes the brand-integrity gate from the same
    reviewed source commit. No hotfix may alter the wordmark, core identity
    colours, tricolour order or Mool launcher after founder review.
23. The Buy zero-item Cart gate passes for Retail, Wholesale and Medicine:
    Clear, final remove/trash, decrement below minimum and recovery removal
    return directly to the relevant catalogue; direct/reloaded empty Cart
    routes normalize; Back does not reopen the empty Cart; a mixed Cart remains
    open while any order group still contains a product; and no `View products`
    or equivalent extra-tap empty-state action is present.
24. The Buy dock terminology gate renders `Shop` for the consumer single and
    small-pack destination and `Wholesale` for MOQ/case-pack purchasing.
    `Retail`, `Personal`, `Everyday` or explanatory quantity wording must not
    reappear as the consumer dock label or its accessibility name.
25. The Buy fulfilment and assistance gate passes across Shop, Wholesale and
    Medicine. Every purchasable offer shows a seller- or supplier-confirmed
    delivery commitment plus the named fulfilment partner and partner type
    before Add. The compact Buy live-order surface opens the matching tracking
    record without overlaying Social. Active Orders contain no repeated
    `Get help` actions. One Mool Assist system provides contextual AI-assisted
    answers and keeps human chat and calls inside MoolSocial; no generic
    `See times`, external dialler/email handoff, internal screenbook
    commentary or unrelated legacy support screen is reachable from it.
26. The Buy reorder-and-address gate passes across Shop, Wholesale, Medicine
    and a mixed Cart. Each delivered order has one Reorder action that opens an
    editable Cart with quantity, remove and Add products; no `Reorder + add`
    duplicate is present. Saved destination types are Home, Work, Third party
    and Other place. Destination type never replaces the receiving person or
    business and receiving contact, which are recorded for every type. Address
    add/edit, automatic-area prefill with manual correction, and third-party
    requests through WhatsApp, MoolSocial and the system share surface pass.
    Shop/Medicine and Wholesale destinations remain independently selectable
    in a mixed Cart. One compact pre-payment address confirmation appears,
    changing either address returns directly to it, and address confirmation
    is invalidated after destination changes or a new repeat purchase.
    Production address requests additionally pass explicit consent,
    data-minimization, deep-link, failure/retry and privacy-policy tests.
27. The Buy Medicine and unified-Cart gate passes. Every Medicine product card
    opens product-specific composition, pack, marketer, sale requirement,
    fulfilment, delivery, storage and support facts. One saved/uploaded
    prescription remains the parent record through pharmacist review. Each
    medicine line is matched by medicine identity, strength, dosage form and
    approved quantity; every verified listed line changes to Add-to-Cart
    without another upload, while unrelated or mismatched medicines remain
    locked. No direct route, restore, quantity or reorder path bypasses
    validation. The visible Cart scopes are ₹ Total, Shop, Wholesale and
    Medicine; each exposes its own count and total and isolates its order
    groups. At supported phone widths, the Medicine grid has no horizontal
    overflow or clipped decision text; a three-column layout is permitted only
    from 360 logical pixels when every required field remains readable.
    Address entry includes receiving contact, street, area, PIN and landmark
    plus current-location, map-pin and Google Maps choices; third-party
    sharing uses named channels or the device share surface and never exposes
    `Any app`.

## Every production promotion

1. Android and iOS staging/production artifacts share the same source commit.
2. Feature is disabled by default and enabled through a reviewed flag.
3. Backup and rollback route are verified.
4. Payment/stock/payout mutations pass duplicate and retry tests.
5. No P0/P1 issue and no blocked core intent path.
6. Founder completes the exact staging acceptance replay.
7. Begin with a percentage rollout; stop automatically on guardrail breach.
8. Record that the promoted source passed the brand-integrity gate. A website
   promotion additionally remains blocked while
   `config/brand-integrity.json` records `pending-alignment`.

## Non-negotiable command behavior

- Every irreversible command has an idempotency key.
- The server owns price, stock, money, eligibility and state transitions.
- Provider callbacks are authenticated, deduplicated and replayable.
- A timeout is not treated as a failure when the authoritative result is
  unknown; the app reconciles before retrying.
- UI success is shown only after an authoritative success response.
