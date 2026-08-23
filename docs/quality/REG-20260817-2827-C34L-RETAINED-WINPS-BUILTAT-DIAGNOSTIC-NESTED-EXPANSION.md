# REG2827 — C34L retained WinPS builtAt diagnostic nested expansion

Date: 17 August 2026
State: registered read-only diagnostic-command failure; zero mutation

## Mistake

The first direct Windows PowerShell parser proof embedded `$formats`, `$wire`,
and `$parsed` inside an outer double-quoted `-Command`. The host expanded them,
producing malformed target text and parser errors; no timestamp proof was
obtained. Exit was nonzero and no file or external action changed.

## Prevention

Place the small timestamp proof in a target-owned temporary fixture script under
the exact repository fixture root and invoke it directly with `-File` on each
host, or use a fully literal non-interpolating command block. Never nest
diagnostic variables in outer double-quoted process arguments.
