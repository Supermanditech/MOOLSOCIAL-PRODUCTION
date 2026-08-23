# UAW C31C broad compiled-artifact inventory truncation

## Incident

A read-only recursive inventory of the C31B evidence directory traversed the
large generated `backend-lib` tree. The resulting output was truncated and is
not accepted as a complete artifact inventory.

## Impact and prevention

No file was changed. C31C reconciliation uses the exact registered C31B source
manifest, state and qualification-document paths already known from machine
state. It does not retry or depend on a recursive compiled-tree listing.
