# C30T multi-file test patch extra hunk marker

- Regression: `REG-20260813-1961-C30T-MULTI-FILE-TEST-PATCH-EXTRA-HUNK-MARKER`
- Date: 2026-08-13
- Scope: test-only patching; the rejected patch made zero changes.

## Incident

An extra hunk marker was placed immediately before the second file header in a
multi-file test patch. Patch parsing rejected the operation before mutation.

## Required prevention

Patch each test owner independently from exact current context. A parser
rejection is zero mutation and is registered before retry.

This record creates no build, upload, install, deployment or device authority.
