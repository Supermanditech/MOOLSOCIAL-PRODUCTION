# AAB C30W gate symbol-search regex rejection

Date: 14 August 2026
Scope: source-only successor AAB preparation audit

A bounded `rg` symbol lookup used an incorrectly escaped regular expression
and was rejected by the regex parser. It returned no admissible audit evidence.
The retry uses fixed strings and bounded line reads only.

No AAB, Play/OPPO action, deployment or secret access occurred.
