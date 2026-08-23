# Web MVP public brand identity copy removal — deployment and audit failures

Date: 2026-08-07 IST
Ticket: `WEB-MVP-PUBLIC-BRAND-IDENTITY-COPY-REMOVAL-20260807`

## Firebase Hosting authentication failure

The exact hosting-only command targeted Firebase project
`moolsocial-dev-503018` after the source, scope, regression, build, tests and
lint gates passed. Firebase CLI rejected the request because the saved session
credentials were no longer valid and requested an interactive reauthentication.
No alternate credential, token or account was accessed. The command reported
no successful release or hosting version.

Prevention is now permanent: resolve the exact authenticated Firebase project
and hosting target with a non-mutating preflight before announcing or issuing a
live deployment. If the session is expired, stop before the write and request
founder-controlled reauthentication.

## Read-only audit command parse failure

After the deploy failure, a read-only PowerShell command intended to compare
line-ending-normalized live and local HTML was composed with malformed nested
CRLF escaping. PowerShell rejected it at parse time, so it read and wrote
nothing. The next audit must use byte-level comparisons or a simpler
escape-insensitive normalization expression.

## State after both failures

- Local production web source remains preserved and fully qualified.
- No credentials were copied, printed or replaced.
- No email was sent.
- No mobile, backend, database or private Sites resource was changed.
- Live verification must determine independently whether the requested public
  identity copy is already present; a failed CLI exit is not proof of live
  content state.

## Retired-brand punctuation variant false negative

The first no-cache live scan searched only for the dotted spelling
`SuperMandi Tech Pvt. Ltd.` and returned zero. A subsequent positive identity
extraction showed that every live route still served
`SuperMandi Tech Pvt Ltd` without periods, including the home page structured
`legalName`. Therefore the requested live change did not deploy and the first
zero result was invalid evidence.

The permanent replacement audit now covers optional punctuation, case and
whitespace variants and positively reads the surviving footer and structured
identity fields. Local source has to pass the same normalized family scan;
production remains pending until authenticated deployment and a fresh live
seven-route audit both succeed.

## Non-interactive reauthentication handshake failure

After the founder offered approval, `firebase login --reauth` was invoked in
the task runner. Firebase rejected it immediately because that runner is
non-interactive, before opening Google sign-in or changing authentication
state. The corrected workflow is to launch a visible, founder-controlled
terminal for only that command, allow the founder to complete sign-in
privately, and then prove the intended project with a separate read-only CLI
preflight before deployment.

## Windows path-glob search failure

A later bounded `rg` search passed `docs\\quality\\*COMPLETION*.md` as a path.
PowerShell did not expand that native-command path glob and ripgrep rejected it
as an invalid filename. No write occurred. Ripgrep evidence searches now use
literal existing roots plus `-g` filename filters.
