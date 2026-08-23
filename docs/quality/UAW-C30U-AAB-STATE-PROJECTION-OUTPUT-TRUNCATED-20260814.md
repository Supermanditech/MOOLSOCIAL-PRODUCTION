# UAW C30U AAB state projection output truncation

Date: 2026-08-14

Ticket: UAW-C30U post-r60.45 Social repairs and Play Internal acceptance

## Incident

The first final AAB machine-state projection exceeded the available transcript
context and was truncated. The attempted read was non-mutating, but its output
is inadmissible evidence and proves none of the intended state assertions.

## Root cause

The required facts fit in one bounded scalar record, but the diagnostic used a
structured projection whose rendering could expand beyond the evidence channel.

## Permanent prevention

Before another qualification action, calculate each comparison explicitly and
emit exactly one semicolon-delimited line containing the machine state, failed
attempt count, successor-seal hash equality, protected file count, successor
gate result, OPPO acceptance state and literal build/upload/install counts.
Reject a missing property, a nonmatching seal hash or any nonzero mutation
count. Never treat truncated output as gate evidence.

No build, upload, release activation or device mutation occurred in this
incident.
