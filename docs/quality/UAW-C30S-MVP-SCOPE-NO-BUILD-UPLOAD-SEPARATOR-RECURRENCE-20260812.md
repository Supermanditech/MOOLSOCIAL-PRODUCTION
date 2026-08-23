# C30S MVP scope no-build-upload separator recurrence

Date: 2026-08-12

The bounded C30S line-by-line transition stopped after thirteen accepted lines
because the next expected exclusion used `no_build upload` while the literal
file contains `no_build_upload`. No later line was attempted.

The accepted prefix remains parseable and is preserved. Continuation must use
only the latest exact `rg -n` output, retain every underscore and stop on the
first rejection before any gate or build authority can advance.
