# C23B scope transition stale-context rejection

- Date: 2026-08-09
- Mutation result: none

The incremental C23B scope patch referenced one dependency line that did not
exactly match the current selected C23A scope JSON. The patch parser rejected
the whole mutation. C23B runtime authority therefore remained closed.

The retry uses the verified current scope document as a complete apply-patch
replacement and validates JSON, ticket digest, delivery lock and scope gate
before any runtime edit.
