# C30T expected ripgrep no-match aborted orchestration

Date: 2026-08-13

The bounded public-share route search allowed ripgrep exit 1 to propagate through the orchestration wrapper. An expected no-match result therefore aborted later independent searches and suppressed their output.

The corrected diagnostic must explicitly distinguish `matches=0` from ripgrep execution errors and fail only for exit codes above 1. No product, backend, provider, device, AAB, Play or communication state changed.
