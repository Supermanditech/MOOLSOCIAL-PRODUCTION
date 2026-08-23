# REG-20260821-3114 — FIX7 primary owner-claim patch stale script context

Date: 21 August 2026
State: registered; rejected patch applied nothing

## Failure

A multi-hunk coordination-policy patch intended to claim FIX7 owners was
atomically rejected because one remembered FIX6 script line did not match the
current policy bytes.

## Impact

- No owner claim, source, test, build, provider, Play or OPPO state changed.
- The rejected patch provides no partial claim authority.

## Root cause

Several distant owner-list insertions were coupled to an unverified remembered
script context instead of current literal policy lines.

## Prevention

Discover each intended existing neighbor in the exact current policy, apply
small claim patches against one verified local context at a time, parse after
each accepted patch, and never couple source, script and evidence claims in
one stale-context operation.
