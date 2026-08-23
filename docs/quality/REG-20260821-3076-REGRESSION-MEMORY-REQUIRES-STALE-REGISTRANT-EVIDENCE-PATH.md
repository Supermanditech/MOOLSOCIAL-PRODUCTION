# REG3076 — regression memory requires stale registrant evidence path

- Date: 2026-08-21
- Status: registered before retry

After REG3075 preserved and moved the stale ignored registrant out of the
Android source set, the regression-memory gate rejected the missing original
path because REG1818 retains it as repository evidence. No build followed.

Prevention: preserve the exact file at both evidence locations and exclude the
original ignored path through the Android source-set configuration instead of
moving or deleting historical evidence.
