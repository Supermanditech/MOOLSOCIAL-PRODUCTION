# C17G aapt relative Windows path and deferred exit check rejection

- Date: 2026-08-08
- Candidate: C17G r60.18
- Scope: read-only postbuild validation; no rebuild, install or device mutation resulted.

The first `aapt dump badging` call received a repository-relative Windows path and failed to load the APK. Its nonzero exit was not checked until after independent signer checks, so package/version output from that aggregate command is inadmissible. Candidate checksum, generated-output identity, v2 signature, signer equality and postbuild source fingerprint did pass independently, but they do not substitute for package badging.

The correction is a read-only retry using the resolved absolute APK path, capturing badging and checking `LASTEXITCODE` immediately before any later validation. No APK is rebuilt or modified.
