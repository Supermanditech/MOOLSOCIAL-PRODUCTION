# C09 multi-file evidence patch hunk failure

Date: 2026-08-07
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION`

A multi-file `apply_patch` update for pre-build evidence contained an extra
hunk delimiter before the next `Update File` header. Patch verification rejected
the complete operation before any file changed.

The evidence updates are split into small patches with one bounded hunk per
file. Every updated file and the final source-manifest hash are read back before
the machine state is armed.
