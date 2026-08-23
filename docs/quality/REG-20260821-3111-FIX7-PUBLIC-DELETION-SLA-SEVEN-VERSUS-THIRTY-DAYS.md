# REG-20260821-3111 — FIX7 public deletion SLA seven versus thirty days

Date: 21 August 2026
State: registered; public policy correction required before Meta review

## Finding

The founder-approved FIX7 ticket sets `completionTargetDays` to 30, while the
public deletion page promises completion within 7 calendar days.

## Impact

- Customer and Meta-review policy is internally contradictory.
- A 7-day public promise may be untruthful when the approved durable process
  permits up to 30 days.
- No source, Hosting deployment, provider, build, Play or OPPO action changed
  during discovery.

## Root cause

The pre-existing public deletion page predates the founder-approved durable
FIX7 erasure policy and was not bound to the ticket's machine-readable SLA.

## Prevention

Update the public deletion page to the approved 30-day maximum, add a public
confirmation-code status view that reports only pending/completed/failed, and
bind source tests to the ticket value so a future public SLA cannot diverge.
No Hosting deployment occurs without its separate action-time authority.
