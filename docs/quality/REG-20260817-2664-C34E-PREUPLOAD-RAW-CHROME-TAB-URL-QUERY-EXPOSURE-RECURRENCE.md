# C34E preupload raw Chrome tab URL query exposure recurrence

Date: 2026-08-17 IST

Status: registered; C34E rejected before any Play write; exact successor required

## Incident

After C34E r60.69 passed its postbuild and dual-host preupload gates at
`1/0/0/0`, browser control requested the complete open-tab inventory and
emitted the returned tab objects. An unrelated signed-in Google Cloud tab
contained a transient query value in its URL. The value is deliberately not
copied, persisted or reproduced in repository evidence.

This repeats the failure class permanently registered by
`REG-20260813-1863-C30T-CLOUD-TAB-URL-QUERY-EXPOSURE`. It occurred before the
Play Internal Testing tab was claimed, before the AAB was attached, and before
any Play write. C34E therefore remains at build/upload/install/device counts
`1/0/0/0` and is rejected without upload, install, promotion or reuse.

## Root cause

The browser handoff used `openTabs()` and serialized every returned object even
though the historical prevention required internal matching plus a redacted
host/path-only projection. The read-only inventory was treated as harmless
browser discovery instead of a secret-adjacent boundary.

## Permanent prevention

The exact successor must not enumerate or emit raw authenticated tab metadata.
It must use a prequalified, user-mentioned exact Play tab or create one fresh
Play Console tab at the known Internal Testing route. If discovery is
unavoidable, matching must occur inside the browser runtime and only a
query-free allowlisted Play host/path summary may leave it. Unrelated tab
metadata, query strings, fragments, account data, tester data, private links,
cookies, storage and session values must never be read or returned.

No C34E AAB upload, Play activation, OPPO update, email, SMS, deployment or
production-readiness claim is allowed.
