# REG2882 — C34L transition REG2878 WinPS UTC negative class

- Status: registered first Windows PowerShell journal failure after corrected PS7 passed.
- Failure: the intentional noncanonical `preparedUtc` negative reached raw-wire rejection on PS7 but exact-timestamp rejection on WinPS, so the single-class oracle failed while journal and targets remained unchanged.
- Root cause: host JSON date coercion changes which of two adjacent fail-closed UTC invariants observes the deliberately malformed wire first.
- Prevention: prefer a host-stable fixture that isolates one invariant; if runtime coercion makes that impossible, explicitly require the exact two host-specific UTC classes keyed by host major, while retaining raw token cardinality, timestamp, no-write, and idempotence assertions.
- Containment: no retry, mutation, real transition, release, private, device, or external action followed.
