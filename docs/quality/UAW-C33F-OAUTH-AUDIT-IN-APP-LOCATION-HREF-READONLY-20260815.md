# UAW-C33F OAuth audit in-app location href read-only

- Recorded at: `2026-08-15T10:56:13.3999916Z`
- Regression: `REG-20260815-2404-C33F-OAUTH-AUDIT-IN-APP-LOCATION-HREF-READONLY`

The browser-control evaluation environment rejected assignment to `location.href` because the controlled location object is read-only. The blank tab remained blank. No Google Cloud page state, OAuth value, account value, or provider state was accessed or changed.

The retry uses the Codex app's supported browser URL action and claims only the exact Dev-project credentials tab it opens.
