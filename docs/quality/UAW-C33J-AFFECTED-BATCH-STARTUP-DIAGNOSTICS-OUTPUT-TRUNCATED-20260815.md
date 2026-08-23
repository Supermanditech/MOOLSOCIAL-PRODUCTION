# UAW C33J affected-batch startup diagnostics output truncation

- Regression: `REG-20260815-2496-C33J-AFFECTED-BATCH-STARTUP-DIAGNOSTICS-OUTPUT-TRUNCATED`
- Failure mode: the exact nine-file batch exited zero with `59` passes, but repeated startup diagnostics caused partial transcript truncation.
- Impact: the pass is preliminary rather than complete retained transcript evidence; no product or external state changed.
- Prevention: replay the identical exact-file command through a bounded terminal-summary filter while preserving the native Flutter exit code.
