# AAB Flutter-manifest stale default expected count

Date: 14 August 2026
Scope: source-only successor AAB preparation audit

The exact 59-file C30W focused manifest completed with Flutter exit zero,
417 authored passes, 3 declared skips, zero authored failures, zero error
events and zero non-JSON lines. The runner still exited one because its default
expected-pass count is the historical C30T value 405.

The result is not claimed as a passing gate until a retry binds the exact
current manifest and an explicit current count. The successor state must pin
both the manifest hash and expected count so a different manifest cannot reuse
it silently.

No AAB, Play/OPPO action, deployment or secret access occurred.

## Resolution

The retry bound the exact 59-file manifest explicitly and passed with 417
authored passes, 3 declared skips, zero failures/errors and Flutter exit zero.
C30X pins the manifest hash, file count and both expected result counts.
