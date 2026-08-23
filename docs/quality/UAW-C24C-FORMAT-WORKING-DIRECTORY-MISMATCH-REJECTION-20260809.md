# C24C formatter working-directory mismatch rejection — 2026-08-09

The connected-navigation verification command ran from `apps/mobile` while
giving `dart format` repository-root-relative `apps/mobile/...` paths. The
formatter found no files, although the later analyzer and exact Work test
passed and left the compound command with a successful final exit code.

REG652 requires formatter paths to match the declared working directory and
requires formatting to be checked separately so a later command cannot mask
an earlier failure.
