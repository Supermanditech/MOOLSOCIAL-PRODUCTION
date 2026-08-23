# REG2768 — C34L blocker/browser durable binding and confinement gaps

Date: 17 August 2026
State: registered independent pre-AAB audit finding; no release action

## Finding batch

Independent review of the green PRE-AAB-3 checker and PRE-AAB-1 readiness
found five release-blocking gaps before the eight-phase matrix:

1. source-seal exclusion compares an uncanonical manifest path string with the
   canonical mutable-ledger relative path. A `..` or case alias can resolve to
   the ledger, pass hash validation and bypass exclusion;
2. readiness invokes blocker/browser integration only for `preupload`, so its
   `source` phase does not enforce ledger exclusion during source qualification;
3. browser proof is external and ephemeral: state and aggregate do not mirror
   its path/SHA/bytes and three route flags, the emitted prerequisite proof does
   not bind them, and no transition persists them;
4. fixture confinement tests raw relative prefixes before canonicalizing, so a
   `tmp/c34l-blocker-browser-fixtures-X/../...` alias can leave the unique run
   root while remaining inside the repository; and
5. freshness trusts booleans rather than a current-session nonce/timestamp and
   producer binding, allowing same-attempt/current-state proof replay despite
   the browser qualification's session-specific rule.

The prior two-positive/eight-negative fixtures passed on both hosts but do not
cover these boundaries. No browser, provider, build, Play, OPPO, device,
private, secret or external action occurred.

## Required correction and prevention

Resolve every manifest owner and reject canonical ledger identity plus aliases
and duplicates. Compose source-phase ledger exclusion from readiness. Add
browser evidence path/SHA/bytes, session identity and route flags to both state
owners and the exact prerequisite proof schema, and validate parity against the
retained proof. Canonicalize fixture paths before requiring the exact unique
run-root prefix. Freshness must use a bounded session-issued timestamp/nonce
and producer identity, not self-asserted booleans. Add dual-host negatives for
all five gaps before PRE-AAB-4 may mutate or run.
