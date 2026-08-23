# C24C state-read filename/wildcard rejection — 2026-08-09

The first closure-state command guessed two absent config filenames and passed
wildcard-bearing Windows paths directly to ripgrep. Only the known C24C ticket
was read successfully.

REG666 requires `rg --files` discovery followed by exact literal-path reads;
wildcards are not used as Windows path arguments.
