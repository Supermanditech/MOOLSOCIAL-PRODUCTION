# UAW-C33F OAuth audit tab-get handle not awaited

- Recorded at: `2026-08-15T10:57:03.9931596Z`
- Regression: `REG-20260815-2405-C33F-OAUTH-AUDIT-TAB-GET-HANDLE-NOT-AWAITED`

The browser discovery check tried to access the page-control surface on an unresolved `tabs.get` promise. It failed before tab discovery and before any Google Cloud page read or provider action.

The retry lists current tabs directly and awaits each selected tab handle before use.
