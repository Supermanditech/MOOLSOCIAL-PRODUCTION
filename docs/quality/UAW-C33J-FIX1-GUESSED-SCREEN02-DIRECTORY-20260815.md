# UAW C33J FIX1 guessed Screen02 directory

- Regression: `REG-20260815-2505-C33J-FIX1-GUESSED-SCREEN02-DIRECTORY`
- Failure: a key lookup included a plausible but nonexistent Screen02 source
  directory and ended with a missing-path error.
- Impact: no source or external state changed; the mixed lookup is not complete
  evidence.
- Prevention: discover owners with `rg --files`, then search verified literal
  roots only.
