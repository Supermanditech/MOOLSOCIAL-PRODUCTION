# C24F Book-count inventory regex rejection — 2026-08-09

The first cross-language search for stale Book action counts used an unbalanced
regex alternation and was rejected by ripgrep before returning any owner list.
No source or acceptance file was changed from that command.

The retry uses separate fixed-string/simple-pattern searches with explicit exit
handling, then patches only the proven current count owners.
