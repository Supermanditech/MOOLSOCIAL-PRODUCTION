# UAW-C33F FIX3 Firebase CLI SHA list exit 2

- Recorded at: `2026-08-15T10:38:21.5106796Z`
- Regression: `REG-20260815-2394-C33F-FIX3-FIREBASE-CLI-SHA-LIST-EXIT-2`
- Scope: read-only diagnosis after repeated Firebase console write failure.

The captured `apps:android:sha:list` process exited with code 2. Its stdout/stderr was not emitted, persisted, or logged by Codex, and no certificate value or credential material was exposed. No CLI mutation command was invoked.

Before retrying, classify only a heavily redacted error category and verify the installed CLI's supported command syntax. `firebase login:list --json` remains prohibited.

The captured stdout was subsequently redacted before inspection and classified the failure as expired Firebase CLI credentials. No raw error, identifier, certificate, token, or account value was emitted. The next action requires the founder to complete interactive `firebase login --reauth`; only then may the read-only SHA-state query be repeated.
