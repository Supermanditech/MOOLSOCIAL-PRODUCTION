# REG2688 — C34G nested-property inventory repeated the empty-pipe class

## Outcome

The inventory command again placed a formatter pipe immediately after statement-level `foreach`. It failed at parse time, produced no schema evidence and changed no file.

## Prevention

Every multi-item diagnostic now uses an explicit result array, terminates `foreach`, and formats only in a later statement. Direct pipes after statement-level `foreach` are prohibited.
