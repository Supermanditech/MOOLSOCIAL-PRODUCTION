# C30T post-build temporary Chrome profile search scope escape — 2026-08-13

## Outcome

A post-build release-note search used a repository-wide scope without excluding
the repository-local tmp tree. It matched an unrelated temporary Chrome Secure
Preferences file and caused session-setting metadata to appear in tool output.
No credential value was used, copied, persisted or acted upon.

## Root cause and prevention

The search excluded normal build and artifact trees but omitted the permanent
session-settings exclusion for temporary browser profiles. All remaining C30T
release reads use exact named durable owners only. Broad dot-scope searches
must exclude tmp, browser profiles, Preferences and Secure Preferences.

This is a post-build operational registry entry. The already sealed AAB remains
bound to its build-time source manifest. It does not authorize or trigger a
second AAB build or second Play upload.
