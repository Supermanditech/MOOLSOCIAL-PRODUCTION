# Release gates

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

## Every production promotion

1. Android and iOS staging/production artifacts share the same source commit.
2. Feature is disabled by default and enabled through a reviewed flag.
3. Backup and rollback route are verified.
4. Payment/stock/payout mutations pass duplicate and retry tests.
5. No P0/P1 issue and no blocked core intent path.
6. Founder completes the exact staging acceptance replay.
7. Begin with a percentage rollout; stop automatically on guardrail breach.

## Non-negotiable command behavior

- Every irreversible command has an idempotency key.
- The server owns price, stock, money, eligibility and state transitions.
- Provider callbacks are authenticated, deduplicated and replayable.
- A timeout is not treated as a failure when the authoritative result is
  unknown; the app reconciles before retrying.
- UI success is shown only after an authoritative success response.
