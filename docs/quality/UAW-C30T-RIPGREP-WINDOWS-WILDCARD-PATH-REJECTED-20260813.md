# C30T ripgrep Windows wildcard path rejection

Date: 2026-08-13

The Social interaction audit used `backend/functions/src/socialContent*` as a positional path. Windows rejected that wildcard path and ripgrep exited 2. Partial matches from other paths are not treated as a completed audit.

The corrected diagnostic must search the proven `backend/functions/src` root and filter files with ripgrep `-g` expressions or a prior `rg --files` inventory. No product, backend, device, AAB, Play or communication state changed.
