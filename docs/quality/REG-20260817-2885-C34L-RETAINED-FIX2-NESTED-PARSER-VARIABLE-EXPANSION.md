# REG2885 — C34L retained FIX2 nested parser variable expansion

- Status: registered pre-parser command failure.
- Mistake: the parser check embedded PowerShell `$` variables in an outer double-quoted `pwsh -Command`; the host expanded them and the inner parser received `foreach( in )`.
- Root cause: an interpolating nested parser wrapper was used despite repeated durable prevention.
- Prevention: parse each owner with the current-host `Parser.ParseFile` directly, or invoke a stable direct `-File` checker; never embed parser variables in double-quoted nested command text.
- Impact: no parser, fixture, memory, owner, recovery, release, private, or external action occurred afterward.
