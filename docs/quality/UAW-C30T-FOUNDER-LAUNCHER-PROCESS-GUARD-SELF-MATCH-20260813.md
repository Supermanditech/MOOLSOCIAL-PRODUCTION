# C30T founder launcher process guard self-match — 2026-08-13

## Outcome

The first visible founder-launcher start attempt made no mutation because its
duplicate-process guard matched the current PowerShell process executing the
guard. The launcher path appeared in that process's own command line, so the
guard stopped before opening another process or consuming build authority.

## Root cause and prevention

The command-line containment check did not exclude the current process ID.
Future launcher checks first remove the current shell process from the result;
only a distinct process with the canonical launcher path can block a new
visible launch.

Because this registry evidence is source-sealed, build authority is returned
to the continuous-audit hold and a fresh two-cycle no-AAB pair is required.
