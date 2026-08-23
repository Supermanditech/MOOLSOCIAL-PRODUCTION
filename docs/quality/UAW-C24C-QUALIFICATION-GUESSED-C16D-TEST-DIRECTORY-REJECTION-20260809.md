# C24C qualification guessed C16D test directory rejection — 2026-08-09

The recombined group passed 117 tests with three retained capture skips, but a
guessed `test/ui_v2/universal` path prevented the C16D owner from loading. The
real file is directly under `apps/mobile/test`.

REG668 requires exact `rg --files` discovery for every qualification test path
before recombination.
