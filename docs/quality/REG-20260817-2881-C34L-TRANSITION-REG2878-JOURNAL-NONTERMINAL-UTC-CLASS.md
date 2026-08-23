# REG2881 — C34L transition REG2878 journal nonterminal UTC class

- Status: registered first affected PowerShell 7 journal failure after lifecycle passed both hosts.
- Failure: the older-unreconciled-nonterminal negative expected its chain class but rejected earlier because `preparedUtc` raw wire spelling changed.
- Root cause: the fixture mutation/serialization no longer preserves canonical UTC wire tokens while attempting to isolate the nonterminal chain invariant.
- Prevention: mutate only the intended journal status/chain field using raw cardinality-preserving substitution or reserialize with exact canonical `.fffZ`; retain a separate UTC-wire negative and statically review remaining journal negatives against validation order before retry.
- Containment: no WinPS journal retry, real transition, release, private, device, or external action followed; lifecycle PS7/WinPS were green.
