# REG2726 — C34J postinstall blocker-ledger circular dependency

Date: 2026-08-17 IST

The newly added all-phase pre-AAB fixture replay reached C34J `postinstall` and
found that the candidate gate invoked the C33G blocker ledger in `postinstall`
mode before device journeys were allowed to run. That ledger mode correctly
requires completed future Play-device acceptance evidence, so the release
lifecycle was circular: postinstall required journey completion while journey
execution was still held by postinstall qualification.

No AAB, upload, Play activation, OPPO action, private-account action, or other
external write occurred. C34J had already sealed source and completed two
cycles, so it is permanently rejected at `0/0/0/0`; its source and evidence are
not repaired or reused as a release candidate.

The corrected successor must use the ledger's `prebuild` contract through
postinstall, then require `postinstall` blocker resolution only at final journey
acceptance. Its fixture must use an isolated resolved-ledger copy and prove all
eight candidate phases on PowerShell 7 and Windows PowerShell before source
cycles or founder input authority.
