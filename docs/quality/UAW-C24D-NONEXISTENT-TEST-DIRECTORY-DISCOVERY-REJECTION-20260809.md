# C24D nonexistent test-directory discovery rejection — 2026-08-09

The focused-test inventory queried a proposed `test/ui_v2/ride` directory
before confirming it existed, so ripgrep returned an I/O error.

REG670 requires discovery from an existing parent and lets the authorized
focused-test patch create the bounded ticket directory with its first owner.
