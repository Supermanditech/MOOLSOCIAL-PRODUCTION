# UAW-C33F OAuth audit in-app new-tab object URL stayed blank

- Recorded at: `2026-08-15T10:55:21.9753313Z`
- Regression: `REG-20260815-2403-C33F-OAUTH-AUDIT-IN-APP-NEW-TAB-OBJECT-URL-STAYED-BLANK`

The in-app browser new-tab call created `about:blank` rather than navigating to the intended Google Cloud credentials page. No OAuth, certificate, application, account or credential value was read, and no provider mutation occurred.

The retry reuses the same blank tab and navigates it directly to the exact Dev-project credentials URL before any bounded safe-metadata inspection.
