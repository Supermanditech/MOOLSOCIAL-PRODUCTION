# C30T YouTube player path-guess rejection — 2026-08-13

A read-only audit command located the YouTube player files under `apps/mobile/lib/core/youtube` but then tried to open a guessed `lib/integrations/youtube` path. The read failed and no file changed.

Prevention: use the exact path returned by `rg` in the next read and never reconstruct a component path from memory.
