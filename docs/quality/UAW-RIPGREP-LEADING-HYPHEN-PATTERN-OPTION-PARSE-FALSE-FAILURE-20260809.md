# Ripgrep leading-hyphen pattern option-parse false failure

Date: 2026-08-09

A temporary prototype CSS-token search passed the pattern
`--shadow-soft|--shadow:` directly to ripgrep. Ripgrep parsed the leading
hyphens as a command option and rejected the command before reading the HTML.

Root cause: the command omitted ripgrep's `--` end-of-options delimiter.

Correction: patterns beginning with a hyphen are always placed after `--`, and
the native exit code is interpreted only for the immediately owned search.

No product source, Flutter code, accepted screenbook, APK or OPPO state was
changed by this false failure.
