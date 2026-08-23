# C20H over-broad artifact provenance search timeout

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

A provenance lookup recursively searched scripts, config, all quality
artifacts and quality documentation for source-manifest construction tokens.
The command exceeded its timeout and returned no admissible inventory. It made
no workspace, APK or device mutation.

## Prevention

Later provenance discovery is bounded to `scripts` and `config`, followed by
direct reads of a known artifact directory. The already-read C17G source
manifest is the format reference; the full artifacts tree is not rescanned.
