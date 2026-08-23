# UAW-C33F OAuth audit Web link disappeared before corrected click

- Recorded at: `2026-08-15T11:03:00.7282477Z`
- Regression: `REG-20260815-2409-C33F-OAUTH-AUDIT-WEB-LINK-DISAPPEARED-BEFORE-CORRECTED-CLICK`

The dynamic Google Cloud credential table re-rendered between readiness inspection and the corrected Web-client click. The exact display-name locator had no match when clicked, so Playwright timed out without navigation or field access.

The final retry waits for the OAuth table and exact Web display name in one fresh locator cycle, clicks once, and requires the unique Web-application detail heading before reading only the display name/application type.
