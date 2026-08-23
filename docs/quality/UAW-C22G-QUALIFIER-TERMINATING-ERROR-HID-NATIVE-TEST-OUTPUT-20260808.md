# C22G qualifier terminating error hid native test output

- Observed: 2026-08-08 after the first corrected C22G cycle reached the
  required Flutter suite and rejected.
- Rejection: the outer diagnostic assigned the qualifier invocation to a
  variable under `ErrorActionPreference=Stop`. The qualifier threw after the
  native exit code, so assignment never completed and the already-produced
  Flutter output was not printed; only the wrapper exception remained.
- Root cause: post-failure output capture depended on successful completion of
  a throwing script.
- Prevention: reproduce a failing native phase directly with verified inputs,
  capture its exit code immediately, and print bounded native output before a
  wrapper throw can short-circuit assignment. The rejected cycle is not
  counted.
