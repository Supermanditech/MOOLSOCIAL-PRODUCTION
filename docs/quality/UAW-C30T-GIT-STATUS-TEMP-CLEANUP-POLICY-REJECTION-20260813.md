# C30T Git status temporary-cleanup policy rejection

## Incident

A dirty-tree retry redirected Git stdout and stderr to newly named files under
the repository `tmp` directory and included a verified cleanup block. The shell
command was rejected by policy before execution because it contained the file
removal operation.

## Impact

The command never executed. It created no temporary file, changed no repository
or Git state, and produced no admissible dirty-tree evidence.

## Prevention

For this compact diagnostic, use `System.Diagnostics.Process` with redirected
stdout and stderr, read both streams asynchronously in memory, and avoid all
temporary filesystem state. Admit the result only when Git exits zero, stderr
is empty, every porcelain record validates and the tool prints only counts and
the deterministic status hash.
