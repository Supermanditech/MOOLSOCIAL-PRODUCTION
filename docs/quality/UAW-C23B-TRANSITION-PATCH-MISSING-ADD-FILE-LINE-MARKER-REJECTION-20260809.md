# C23B transition patch-format rejection

- Date: 2026-08-09
- Mutation result: none

The first C23A-to-C23B transition patch omitted the leading `+` on one wrapped
Add File line. The patch parser rejected the whole mutation. No ticket, scope,
runtime, build, install or device state changed.

Future transition patches keep Add File blocks bounded and validate the marker
on every added line before invocation.
