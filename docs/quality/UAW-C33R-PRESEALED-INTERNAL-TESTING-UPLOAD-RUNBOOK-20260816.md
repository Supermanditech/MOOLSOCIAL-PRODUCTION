# C33R pre-sealed Internal Testing upload runbook

Date: 2026-08-16 IST

This owner exists before the C33R source seal so no ad-hoc repository discovery
is permitted after its AAB. It applies only to
`UAW-C33R-R60-56-AUTHENTICATION-NO-REGRESSION-PLAY-OPPO-ACCEPTANCE`,
version `1.0.0-r60.56` / `2026081356`.

## Immutable workflow boundary

1. Before the source seal, inventory and verify every local gate, evidence
   owner and browser workflow reference. All native exit codes are asserted
   immediately. The authoritative Flutter runner receives the focused manifest
   only as the literal repository-relative path; orchestration must never pass
   an absolute path that the runner would join to `RepositoryRoot` again.
2. After the source seal, repository discovery commands are prohibited. Only
   the sealed C33R phase gate, literal artifact/hash checks and the exact
   already-qualified browser steps in this document may run. After two cycles,
   persist only the cycle results while every later authority remains held;
   pass `source` in both PowerShell hosts, then expose build authority and run
   `build` in both hosts. Those two lifecycle transitions cannot be combined.
3. After AAB success, `postbuild` must pass before state can expose one
   `preupload` authority. The exact AAB SHA and byte count are rebound
   immediately before file selection.
4. The browser must resolve a fresh signed-in MoolSocial Play Console app route
   from the live app dashboard and navigate semantically to Testing > Internal
   testing. Saved opaque track URLs are not reused.
5. Only the visible Internal Testing **Create new release** or recoverable
   existing draft is permitted. The exact sealed AAB is attached once through
   the supported file chooser. A chooser timeout does not authorize another
   attachment until the live draft is inspected and proved empty.
6. Release notes use the Console-provided locale editor without inventing
   locale tags. Every version name/code and track label is read back before the
   final review action.
7. The final publish/rollout confirmation is accepted only when the visible
   dialog and button are semantically scoped to Internal Testing. No open,
   closed, production, public, alpha, beta or other track is permitted.
8. After activation, retained Play evidence must prove exact package, version
   code, version name, track and artifact identity before one in-place OPPO
   Play update authority is exposed.
9. No post-seal source, registry, ticket, runbook or gate mutation is allowed.
   Any new defect, tooling mistake or required repository mutation rejects the
   candidate before the next external action.

## Live browser prequalification boundary

The founder completed visible Google sign-in and manually opened Internal
Testing. Read-only sanitized proof now binds the MoolSocial app dashboard,
package `com.moolsocial.app`, the `/tracks/internal-testing` route shape, the
visible `Internal testing` heading, the unique `Create new release` button and
the preserved active r60.49 release. No account/app opaque identifier was
retained and no Play write occurred. Exact qualification is
`docs/quality/UAW-C33R-PRESEALED-INTERNAL-TESTING-BROWSER-QUALIFICATION-20260816.md`.

REG2616 through REG2620 remain permanent prevention evidence. After the source
seal, no selector, coordinate or keyboard navigation experiment is allowed.
The retained Internal Testing tab and this exact workflow are the only browser
entry points. A missing or changed semantic control stops the release before
any file attachment.

## Retained prevention evidence

- `docs/quality/UAW-C30O-PLAY-SAVED-INTERNAL-TRACK-URL-UNEXPECTED-ERROR-REJECTION-20260812.md`
- `docs/quality/UAW-C30Q-PLAY-UPLOAD-BUTTON-FILE-CHOOSER-TIMEOUT-REJECTION-20260812.md`
- `docs/quality/UAW-C30S-CHROME-FILE-CHOOSER-TIMEOUT-20260813.md`
- `docs/quality/UAW-C30S-PLAY-RELEASE-NOTE-LOCALE-TAG-LAYOUT-REJECTION-20260813.md`
- `docs/quality/UAW-C30V-PREUPLOAD-GATE-INVOKED-AFTER-DRAFT-FILE-ATTACHMENT-20260814.md`
- `docs/quality/UAW-C30V-PLAY-PREVIEW-TAB-STALE-AFTER-CONFIRMATION-TURN-20260814.md`
- `docs/quality/UAW-C33F-PLAY-CONSOLE-EVALUATED-DOM-COMPARE-DOCUMENT-POSITION-UNAVAILABLE-20260815.md`
- `docs/quality/UAW-C33F-PLAY-CONSOLE-EVALUATED-DOM-BUTTON-CLICK-NOT-CALLABLE-20260815.md`
- `docs/quality/UAW-C33F-PLAY-CONSOLE-LOCATOR-DIRECT-SCROLL-METHOD-UNAVAILABLE-20260815.md`
- `docs/quality/UAW-C33F-PLAY-PUBLISH-CONFIRMATION-DIALOG-ACCESSIBLE-NAME-INCLUDED-CLOSE-20260815.md`
- `docs/quality/REG-20260816-2611-C33N-POSTBUILD-EVIDENCE-LOOKUP-GUESSED-NONEXISTENT-RELEASE-DIRECTORY.md`
- `docs/quality/REG-20260816-2612-C33N-REJECTION-COMPOUND-PATCH-HANDOFF-CONTEXT-MISMATCH.md`
- `docs/quality/REG-20260816-2616-C33O-PLAY-DEVELOPER-SELECTOR-GENERIC-BUTTON-LOGIN-REDIRECT.md`
- `docs/quality/REG-20260816-2617-C33O-PLAY-INTERNAL-TESTING-TEXT-SPAN-CLICK-TIMEOUT.md`
- `docs/quality/REG-20260816-2618-C33O-PLAY-INTERNAL-TESTING-PARENT-ANCHOR-CLICK-TIMEOUT.md`
- `docs/quality/REG-20260816-2619-C33O-CHROME-DOM-RECTANGLE-COORDINATE-OFFSET-OPENED-TESTING-SECTION.md`
- `docs/quality/REG-20260816-2620-C33O-PLAY-INTERNAL-TESTING-ANCHOR-KEYBOARD-ACTIVATION-TIMEOUT.md`
- `docs/quality/REG-20260816-2626-C33P-FLUTTER-RUNNER-ABSOLUTE-MANIFEST-DOUBLE-ROOT.md`
- `docs/quality/REG-20260816-2627-C33Q-SOURCE-GATE-AUTHORITY-EXPOSED-BEFORE-FINAL-SOURCE-REPLAY.md`

All listed paths were verified before C33R selection. This document does not
authorize a build, Play write, OPPO mutation, secret access or deployment.
