# REG-20260815-2533 C33L Windows rg wildcard positional-path recurrence

- Date: 2026-08-15
- Predecessor class: REG-2436, REG-2456, REG-2488 and REG-2503.
- Failure: a C33L read-only inventory passed `scripts/qualify*` as a positional
  ripgrep path on Windows. The path was rejected with OS error 123 after an
  earlier search clause had emitted a useful match.
- Impact: no repository, build, external-service, Play or OPPO state changed;
  the combined command is not accepted as complete evidence.
- Prevention: use exact verified file paths, or a directory root with an
  `rg --glob` filter. Positional wildcard paths are prohibited for C33L.
- Resolution: the implementation memory gate passed with 2,504 entries and
  the corrected `rg --glob` inventory completed without path errors.
