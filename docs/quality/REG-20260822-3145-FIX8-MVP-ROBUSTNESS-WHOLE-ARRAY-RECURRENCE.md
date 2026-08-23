# REG-20260822-3145 — FIX8 MVP robustness whole-array recurrence

Date: 22 August 2026

State: registered; zero robustness-array mutation

A freshly read complete robustness-coverage block was still rejected when used
as one whole-array replacement in the large MVP scope state. No array value or
other machine state changed from the rejected patch.

Root cause: whole-array patch matching remains unreliable in this dense mutable
owner even after local readback; continuing the same replacement shape would
repeat the failed method.

Prevention: never retry a whole-array replacement for this transition. Replace
one unique current string per patch, parse the selected array after every line,
and stop before any ambiguous or nonunique substitution.
