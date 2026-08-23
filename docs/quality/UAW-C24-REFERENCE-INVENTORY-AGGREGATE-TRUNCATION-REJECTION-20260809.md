# C24 reference inventory aggregate truncation rejection — 2026-08-09

## Rejected attempt

The second C24 production-owner inventory launched Book, Work and Medicine/Bus searches as separate shell calls, then emitted every verbose result into one orchestration response. The combined response contained 719 lines and was truncated, so it cannot authorize C24 ticket selection or runtime mutation.

## Preserved truthful observations

- The exact current Book routes and existing Doctor/Salon owners were visible before truncation.
- The exact Bus duplicate count was one, and that sole match was the regression-memory prevention sentence rather than a production owner.
- Medicine has multiple accepted Buy production, policy and test owners.
- The unseen or truncated portions remain unverified and are not treated as evidence.

## Required prevention

Every remaining category audit returns only:

1. a machine-counted set of unique source-owner paths;
2. exact route declarations with a small fixed cap;
3. an explicit duplicate count and capped sample; and
4. no aggregation with another verbose category result.

This rejection is permanently registered as `REG-20260809-606-C24-INDEPENDENT-SEARCHES-RECOMBINED-INTO-TRUNCATED-AGGREGATE`.
