# Post-seal optional inventory Promise.all exit-1 recurrence

The first read-only post-seal audit inventory combined three required document
reads with one optional C32Y/C33 filename search in `Promise.all`. The optional
search validly found no matches and exited 1, causing the orchestration wrapper
to suppress all successful sibling outputs.

No file, test, device or external state changed. REG-2293 must be registered
before retry. Required reads will be run independently; optional inventories
will normalize ripgrep exit 1 to an explicit no-match result before any
aggregation.
