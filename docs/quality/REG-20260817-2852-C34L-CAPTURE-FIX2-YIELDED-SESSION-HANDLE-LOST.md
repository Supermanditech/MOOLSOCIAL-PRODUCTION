# REG2852 — C34L capture FIX2 yielded-session handle lost

Date: 17 August 2026
State: registered unknown first PS7 checker result; zero qualification evidence

## Mistake

The fresh PS7 source-attestation checker exceeded the initial 30-second wait and
returned a live execution session, but the agent wrapper emitted only
`r.output` and discarded `session_id` and exit metadata. Visible output is empty;
the process may still be running, so the attempt is zero qualification evidence.
No retry or later mutation followed.

## Prevention

Always preserve and inspect the complete execution result. If a session ID is
returned, poll that exact session to completion before any new command. When the
handle has already been lost, first perform one bounded process probe for the
exact checker command, terminate only a proven orphan if necessary, then rerun
under a retained handle after the memory gate.
