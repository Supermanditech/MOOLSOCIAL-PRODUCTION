# C21 format-fragile provider-glyph gate rejection — 2026-08-08

The first C21C gate run rejected the implemented provider glyph width/height because Dart formatter wrapped the expression after `width:` and `height:`. Focused analysis and 10 tests had passed, but the static gate required an exact one-line string.

Source gates for formatter-controlled Dart expressions use whitespace-tolerant regexes. Exact literal checks remain appropriate only for stable declarations. The failed gate result is not accepted as qualification evidence.
