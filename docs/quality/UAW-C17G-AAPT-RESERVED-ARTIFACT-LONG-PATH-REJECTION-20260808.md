# C17G aapt reserved-artifact long-path rejection

- Date: 2026-08-08
- Candidate: C17G r60.18
- State: read-only validation-path rejection; no rebuild, install or APK mutation resulted.

The resolved absolute reserved-artifact path still could not be loaded by Android build-tools 36.0.0 `aapt` because the deeply nested descriptive Windows path exceeded the tool's asset-path boundary. Immediate exit checking correctly rejected the attempt.

The guarded wrapper already proved the reserved artifact and the shorter Flutter generated output are the same 134,427,417 bytes with SHA-256 `88F82D203E1C8C565BE5DEBB61E6C1EF1F9E588017EADB9120D97B4B3081ED2C`. Package/version badging may therefore be read from the shorter generated-output path and attributed to the reserved artifact only while that checksum equality remains exact. No copy, rename or rebuild is permitted.
