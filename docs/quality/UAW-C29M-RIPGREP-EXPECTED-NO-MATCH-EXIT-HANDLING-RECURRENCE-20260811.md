# C29M ripgrep expected-no-match exit handling recurrence

- Date: 2026-08-11
- Scope: browser proof-journey reuse audit
- Result: no matching owner; no mutation

The bounded `apps/web` search returned no YouTube provider, private-upload, Social content or App Check client owner. Ripgrep correctly used exit code 1 for no matches, but the wrapper treated it as a tool failure.

Future negative audits explicitly accept exit code 1 and reserve failure for values above 1. The result is retained: there is no existing browser journey that can replace the native authenticated/App-Check proof.
