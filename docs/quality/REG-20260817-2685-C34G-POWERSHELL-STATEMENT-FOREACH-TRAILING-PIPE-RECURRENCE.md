# REG2685 — C34G statement-`foreach` trailing-pipe recurrence

## Outcome

A read-only ticket inventory repeated the registered empty-pipe parser class by piping directly after a statement-level `foreach`. It produced no inventory and changed no ticket or source owner.

## Prevention

Assign the `foreach` output to an explicit array, terminate that statement, and format the array separately. The failed inventory is never counted.
