# REG2880 — C34L retained FIX2 attempt negative reaches history equality first

- Status: registered next fresh PowerShell 7 fixture failure; no retry.
- Failure: the transaction-history attempt fixture mutates only detailed history, so the strengthened detailed/aggregate equality invariant correctly rejects before the older ticket/attempt oracle.
- Root cause: the fixture no longer isolates attempt semantics under the new parity-first validation order.
- Prevention: classify this asymmetric fixture as a history-equality negative and add/retain a separate symmetric wrong-attempt proof negative so attempt validation is exercised after parity.
- Containment: cleanup ran; no WinPS run, real recovery, release, private, device, or external action.
