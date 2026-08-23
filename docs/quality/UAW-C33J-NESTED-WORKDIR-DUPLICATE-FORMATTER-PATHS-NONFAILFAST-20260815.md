# UAW C33J nested-workdir duplicate formatter paths and non-fail-fast command

- Regression: `REG-20260815-2492-C33J-NESTED-WORKDIR-DUPLICATE-FORMATTER-PATHS-NONFAILFAST`
- Failure: after changing to `apps/mobile`, the formatter still received `apps/mobile/...` paths. A semicolon then allowed tests to run after that missing-path result.
- Impact: formatting supplied no evidence; the independently started test exposed a separate layout defect. No external state changed.
- Prevention: use `lib/...` and `test/...` inside `apps/mobile`, and separate formatter and test invocations so a failed step cannot be skipped.
