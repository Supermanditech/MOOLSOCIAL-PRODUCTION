# C30T Cloud preflight Functions ignore-list mismatch

Date: 2026-08-13

After Firebase authentication and immutable UI locks passed, the YouTube Cloud preflight failed closed because the current Firebase Functions ignore array differs from its older exact expected inventory. No deployment was attempted.

Permanent prevention: compare both arrays structurally, prove every additional exclusion is test-only or review-corpus-only and no required runtime source is hidden, then update only the preflight expectation plus its focused control test.
