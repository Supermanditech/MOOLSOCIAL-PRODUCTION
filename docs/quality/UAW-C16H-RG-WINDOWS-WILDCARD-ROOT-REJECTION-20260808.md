# UAW C16H rg Windows wildcard-root rejection — 2026-08-08

## Rejection

The first signer-evidence lookup supplied `rg` a Windows root path containing `*`. Windows rejected the root as an invalid filename before any evidence was read. The already-built APK and installed predecessor were unchanged.

## Prevention

The corrected lookup uses literal repository roots with `-g` filters or exact known predecessor paths. Signer validation remains closed until an actual Android build-tool result is obtained.
