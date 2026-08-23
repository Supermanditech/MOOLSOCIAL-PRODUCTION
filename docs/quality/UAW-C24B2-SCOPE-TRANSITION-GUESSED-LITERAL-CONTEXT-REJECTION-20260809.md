# C24B2 scope transition guessed literal-context rejection — 2026-08-09

The first C24B1-to-C24B2 scope transition patch guessed two exclusion strings with different underscore/space boundaries from the literal state file. `apply_patch` rejected the complete transition atomically; the active scope state therefore remained C24B1 and no C24B2 runtime authority was created.

The retry reads the current literal assessment and ticket blocks and replaces those exact blocks. This mistake is permanently registered as `REG-20260809-617-C24B2-SCOPE-TRANSITION-PATCH-GUESSED-LITERAL-SPACING`.
