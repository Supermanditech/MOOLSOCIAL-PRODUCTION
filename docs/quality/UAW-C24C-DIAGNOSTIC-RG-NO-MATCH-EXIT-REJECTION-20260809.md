# C24C diagnostic ripgrep no-match exit rejection — 2026-08-09

A diagnostic loop found the required Ride lifecycle owners, then ended with an
expected no-match in an unrelated test file. Ripgrep exit code 1 consequently
marked the whole read-only command failed.

REG658 requires multi-file ownership searches to distinguish expected no-match
from real command failure.
