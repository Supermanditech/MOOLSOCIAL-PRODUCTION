# C25F C24B3 repeated Chat semantics finder rejection

- Date: 2026-08-09
- Status: registered before retry

The migrated C24B3 test repeated REG-20260809-788 by resolving `Open Chat` through a semantics-label finder that selected the outer composite node rather than the interactive IconButton node. All other seven active tests in the file passed.

The correction uses the unique `Open Chat` tooltip finder already proven by the C25F focused gate and leaves the runtime control unchanged.
