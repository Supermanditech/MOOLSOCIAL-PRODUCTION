# Web MVP public brand identity copy removal — qualification and cleared deployment hold

Date: 7 August 2026 IST
Ticket: `WEB-MVP-PUBLIC-BRAND-IDENTITY-COPY-REMOVAL-20260807`
Branch: `remediation/prototype-conformance-2026-07-20`
HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`

## Outcome now

The requested replacement is complete in the preserved local production web
source for the home, privacy, terms, support, disconnect, delete-account and
YouTube API routes. Both visible footer copy and the home-page structured
`legalName` use `moolsocial.com`. Dynamic app metadata remains in parity with
the Firebase static source.

The first hosting-only Firebase command stopped because the saved CLI session
had expired. After explicit founder approval, the founder privately completed
reauthentication in a visible terminal. A read-only preflight then resolved
the exact active project and hosting site, and the hosting-only retry completed
successfully. Codex did not handle a password or alternate credential. No
commit, push or broader deployment occurred.

## Qualified source files

- `apps/web/app/layout.tsx`
- `apps/web/app/LandingPage.tsx`
- `apps/web/public/index.html`
- `apps/web/public/privacy/index.html`
- `apps/web/public/terms/index.html`
- `apps/web/public/support/index.html`
- `apps/web/public/disconnect/index.html`
- `apps/web/public/delete-account/index.html`
- `apps/web/public/youtube-api/index.html`
- `apps/web/tests/firebase-public-site.test.mjs`

## Machine results

- Punctuation-tolerant local retired-brand scan: zero matches.
- MVP scope gate: authorized for the exact ticket.
- Codex development regression gate: passed with 122 registered entries.
- Production web build: passed.
- Public-site tests: 7 passed, 0 failed.
- Lint: 0 errors; 2 existing `no-img-element` warnings.
- Seven intentional character-level public-copy digests are relocked.
- Exact local route hashes are recorded in
  `config/web-mvp-public-brand-identity-copy-removal-state.json`.

## Live state after the successful retry

All seven no-cache route requests returned HTTP 200. The normalized retired
identity family has zero matches, every footer is `© 2026 moolsocial.com`, and
the home structured `legalName` is `moolsocial.com`. Every live route SHA-256
exactly equals its qualified local file.

## Hold cleared and completion gate

The founder-controlled Firebase reauthentication and read-only project
preflight completed. Codex then ran only:

`firebase deploy --only hosting --project moolsocial-dev-503018`

HTTP 200, zero punctuation/case/spacing variants of the retired identity,
positive `moolsocial.com` footer and structured-identity extraction, and
live/local byte identity all pass for seven routes. Functions, database,
mobile, the private Sites project and email remained out of scope.

## YouTube reply readiness

The latest YouTube reply asks for a valid Android mobile-application link.
There is no verified Google Play testing, Firebase App Distribution or other
reviewer-install URL in current evidence. The public YouTube API policy page is
not an application link. The reply should wait until a controlled Android
distribution link is created and reviewer access is verified. No email was
sent and no APK was distributed during this ticket.
