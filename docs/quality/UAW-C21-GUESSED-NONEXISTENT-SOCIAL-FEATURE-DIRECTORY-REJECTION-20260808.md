# C21 guessed nonexistent Social feature directory rejection — 2026-08-08

The first C21C reuse search included the guessed root `apps/mobile/lib/features/social`, which does not exist. Ripgrep reported the missing root. The valid Social owner was still found under `apps/mobile/lib/ui_v2/social`, and no file was changed by the search.

Feature roots must come from `rg --files apps/mobile/lib` before content searches. C21C uses only the discovered `ui_v2/social` owner and exact asset paths.
