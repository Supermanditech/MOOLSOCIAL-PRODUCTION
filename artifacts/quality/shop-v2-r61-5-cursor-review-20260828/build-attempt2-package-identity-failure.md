# Build attempt 2 — package identity rejection

- Candidate: `UAW-SHOP-V2-R61.5-CURSOR-UI-REVIEW-20260828`.
- Source: `9a05a49a5979671e4d7a21f4fb572b57dfb0b847`.
- Result: Gradle assemble succeeded; wrapper plugin-integrity failed before
  review-artifact copy.
- Rejected APK bytes: `206411291`.
- Rejected APK SHA-256:
  `A71A229D14106DE671C42EF0D0A30F882203932E04193155A7EE99E429CAE9A4`.
- Install state: forbidden; no device action occurred.

Read-only inspection and the corrected integrity gate prove:

- application ID: `com.moolsocial.app.cursorreview`;
- version name: `1.0.0-r61.5-cursorreview`;
- version code: `2026082807`;
- required Flutter/Firebase Core/Share Plus classes: present.

The wrapper rejection was false: Windows `apkanalyzer.bat` echoed commands and
the gate concatenated every output line. Attempt 2 remains `consumed_failed`
because the wrapper transaction did not finish or copy a review artifact. Its
APK remains rejected evidence and will not be installed or manually promoted.
