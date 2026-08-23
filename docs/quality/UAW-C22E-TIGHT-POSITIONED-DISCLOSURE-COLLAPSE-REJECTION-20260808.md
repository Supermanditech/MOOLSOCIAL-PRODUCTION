# C22E tight Positioned disclosure rejection — 2026-08-08

Diagnostics proved the selected Buy callback fired: semantics changed from `Hide Buy options` to `Show Buy options` and bridge opacity reached `.5` after 80 ms. The region remained 52 px because a tight `Positioned(height: 52)` overrode `Align.heightFactor`. REG-20260808-537 requires loose child geometry inside the fixed bridge canvas.
