# REG-20260822-3144 — FIX8 MVP top-ticket context rejection

Date: 22 August 2026

State: registered; zero top-level ticket mutation

The attempted complete top-level FIX8 ticket replacement was rejected because
one current FIX5 test-plan string contains a literal space where the patch used
an underscore. The operation was atomic and the top-level executable ticket
remains FIX5.

No runtime source, tests, build, APK, OPPO, provider, account, email/SMS, Play
or cloud state changed from the rejected patch.

Root cause: a long complete-object replacement retained one manually normalized
token instead of the exact live JSON text.

Prevention: patch top-level ticket identity and scalar fields first, then each
named array from an immediate exact local read. Parse and count each field; do
not use another complete-object replacement.
