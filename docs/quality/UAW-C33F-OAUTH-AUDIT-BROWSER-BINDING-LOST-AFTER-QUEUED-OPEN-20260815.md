# UAW-C33F OAuth audit browser binding lost after queued open

- Recorded at: `2026-08-15T10:57:49.4307097Z`
- Regression: `REG-20260815-2406-C33F-OAUTH-AUDIT-BROWSER-BINDING-LOST-AFTER-QUEUED-OPEN`

The Codex browser URL action returned queued. When browser discovery resumed, the previously persistent browser binding was undefined, indicating the control session had reset or disconnected. No Google Cloud page, OAuth identifier, account value, or provider state was accessed.

Recovery follows the Browser skill exactly: initialize the runtime if absent, select by the exact target URL, emit and read complete documentation, then discover only allowed-domain tabs without reusing stale tab IDs.
