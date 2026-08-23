# UAW-C33F OAuth audit Web detail Name locator stayed on list

- Recorded at: `2026-08-15T11:01:57.3374960Z`
- Regression: `REG-20260815-2408-C33F-OAUTH-AUDIT-WEB-DETAIL-NAME-LOCATOR-STAYED-ON-LIST`

The auto-created Web client click was followed by an unverified detail-form assumption. The generic `Name` label instead matched three credential-list table headers and strict mode rejected the read. No OAuth client-ID, certificate, account, or credential value was accessed.

The retry verifies the current tab and controlled-tab inventory first, then scopes any detail-form read behind the unique `Client ID for Web application` heading.
