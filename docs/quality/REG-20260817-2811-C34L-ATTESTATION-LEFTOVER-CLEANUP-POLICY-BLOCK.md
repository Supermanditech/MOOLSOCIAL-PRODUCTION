# REG2811 — C34L attestation leftover-cleanup policy block

Date: 17 August 2026
State: registered pre-launch policy rejection; zero filesystem mutation

## Mistake

The exact-leftover cleanup script validated the intended checker-owned target
but still contained recursive `Remove-Item`. Command policy rejected the script
before process launch, so no junction unlink or filesystem mutation occurred.

## Prevention

Use the already required `DirectoryInfo` API end to end: verify and unlink the
exact junction with `.Delete()`, then verify the unique checker-owned root and
delete it with `.Delete($true)`, followed by exact absence assertions. Do not
include `Remove-Item` in this cleanup path.
