# C24G repeated mobile-CWD read path masked by format rejection — 2026-08-09

After REG731, a compound verification again ran from `apps/mobile` but passed
an `apps/mobile/...` path to `Get-Content`. The read failed. The later formatter
succeeded and made the compound shell exit zero, repeating both the
working-directory and final-exit masking mistakes.

This repeat is separately registered. Later commands from `apps/mobile` use
only `lib/...` and `test/...` paths, and source reads are invoked separately
from format or analysis.
