# C30S parallel audit expected-no-match batch rejection

Date: 2026-08-12

During the pre-build release audit, one read-only ripgrep absence check returned
its normal no-match exit code (`1`). The parallel orchestration treated that as
a failed tool call and did not return the other independent results. No source,
artifact, device, provider, Play or Firebase state changed.

Prevention is permanent: every absence-proof ripgrep check must explicitly
accept exit codes `0` and `1`, reject only execution errors, and emit a
structured empty result. The C30S qualifier encodes this behavior rather than
depending on shell success semantics.
