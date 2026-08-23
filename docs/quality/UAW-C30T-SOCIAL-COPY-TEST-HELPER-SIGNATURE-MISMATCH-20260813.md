# C30T Social copy test helper signature mismatch

Date: 2026-08-13

The first isolated Social customer-copy test did not compile because its moved test body passed a `size` named argument. The destination file's existing `_mount` helper has no named parameters and already fixes the viewport to 390 × 844.

Permanent prevention: inspect and reuse the destination helper contract before moving test cases. The failed compile log remains immutable evidence.
