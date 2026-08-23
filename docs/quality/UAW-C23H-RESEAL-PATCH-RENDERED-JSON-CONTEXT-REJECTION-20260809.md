# C23H reseal patch rendered-JSON context rejection

Date: 2026-08-09

The first post-registration reseal patch used indentation copied from a
`ConvertTo-Json` projection. The authoritative C23H ticket is stored as one
minified line, so `apply_patch` could not find the expected indented source
line and rejected the complete multi-file patch atomically. No ticket, machine
state or prebuild seal changed in that attempt.

The corrected workflow reads literal current source from each owner and patches
each file independently. A diagnostic JSON rendering is never used as edit
context.
