# C30T Creator route regex quoting ambiguity

Date: 2026-08-13

The first internal Creator-route query mixed shell and regex quote-class syntax and returned no output with exit code 1, including for known Creator copy. It was rejected as evidence of absence.

Permanent prevention: use separate `rg -F` fixed-string queries for routes and known copy markers and require the known marker to be found before interpreting results.
