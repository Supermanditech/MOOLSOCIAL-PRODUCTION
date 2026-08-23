# REG2884 — C34L retained FIX2 status/hash foreach-pipe recurrence

- Status: registered first unexpected static-review command failure.
- Mistake: a scoped status/hash one-liner piped directly from a statement-level PowerShell `foreach`, producing `An empty pipe element is not allowed` before evidence collection.
- Root cause: the permanently registered foreach-to-pipeline construction was reused.
- Prevention: assign loop results to a variable before piping or emit one owner identity per command; never pipe directly from statement-level `foreach`.
- Impact: no owner/test/memory execution, mutation, recovery, release, private, or external action followed.
