# C30B registry patch result output truncation rejection

- Regression: `REG-20260811-1356-C30B-REGISTRY-PATCH-RESULT-OUTPUT-TRUNCATION-REJECTION`
- Date: 2026-08-11
- Scope: C30B OPPO founder-review evidence closure.
- Failure: a combined registry-and-evidence patch returned truncated output, leaving the mutation result unknown.
- Permanent prevention: register the truncation before inspection, verify the prior regression ID and evidence path separately with bounded checks, and never infer mutation success from truncated output.
