# C10C optional documentation lookup grouping recurrence

## Observation

A required registry read and an optional `rg` documentation lookup were grouped in one command. The documentation lookup correctly found no match but returned exit code 1, which marked the whole command failed after valid registry output.

## Permanent prevention

Required reads and optional lookups run separately. Optional `rg` accepts exit 0 for matches, exit 1 for no matches, and rejects only exit codes greater than 1.
