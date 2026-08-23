# C30T Feed card context stale after preflight scroll

Date: 2026-08-13
Disposition: resolved harness mistake; stopped before product action

## What happened

The share-copy retry normalized the Share semantics but searched for the Asha
carousel description retained from the prior viewport. Its preflight scroll
had already moved that carousel off-screen and exposed two different Asha
cards. The contextual assertion therefore stopped with zero matches.

## Permanent rule

Every scroll invalidates the previous viewport's card identity. The next tap
must be bound to the exact post-scroll hierarchy: current public author,
current card description, enabled/clickable action, exact bounds and current
MoolSocial foreground. Prior viewport context is never reused.

The stopped attempt made no tap, external share or clipboard read.
