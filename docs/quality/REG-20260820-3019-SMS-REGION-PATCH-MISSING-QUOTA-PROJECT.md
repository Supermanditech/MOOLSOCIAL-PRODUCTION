# REG-20260820-3019 SMS region PATCH missing quota project

## Incident

The founder submitted the bounded Identity Toolkit project-config PATCH to set
an India-only SMS allowlist. The API rejected the authenticated user-credential
request because no quota project was attached. The sanitized response retained
`smsRegionConfig: null`.

## Impact

- No SMS region configuration changed.
- No real phone number, SMS, OTP, access token or credential value was printed
  or returned to Codex.
- No funds, deployment, build, Play or OPPO action occurred.
- The rejected PATCH is not accepted as provider-write evidence.

## Root cause

The Identity Toolkit Admin API requires user-credential requests to identify a
quota project. The request carried an access token but omitted the
`X-Goog-User-Project` header.

## Prevention

Do not retry the prior command. Add exactly one quota-project header bound to
the selected Dev project, retain the exact `sms_region_config` update mask and
India-only body, and emit only the resulting region policy plus a sanitized
error field. Never print the access token or full project configuration.
