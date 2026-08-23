# C30O Windows PowerShell native-stderr build-authority recurrence

Date: 2026-08-12

## Rejected attempt

The founder launched the qualified C30O helper from Windows PowerShell 5.1.
After the build gate consumed the one exact C30O authority, Flutter emitted a
benign Kotlin Gradle Plugin warning on native stderr. With
`$ErrorActionPreference = 'Stop'` and merged native redirection, Windows
PowerShell promoted that warning to a terminating `NativeCommandError` at the
Flutter invocation.

This is a recurrence of permanent regression
`REG-20260806-005-WINDOWS-POWERSHELL-NATIVE-STDERR`.

## Preserved result

- C30O machine state is `single_release_AAB_failed_authority_consumed`.
- Exactly one wrapper invocation and one attempted build are recorded.
- No generated or sealed AAB and no provenance file exist.
- No upload or install occurred; r60.40 remains installed on OPPO `2b3e0f71`.
- The transient Firebase define file was erased by the founder helper.
- No password, API key, private key, token, nonce or private verdict was read,
  printed, copied or retained by Codex.

## Mandatory prevention

C30O is permanently closed and must never be rerun. Any successor must have a
new exact ticket and candidate identity, require PowerShell 7 before founder
prompts or authority consumption, capture native stdout and stderr without
turning informational stderr into a terminating PowerShell error, and pass
the complete source, MVP, delivery, regression and build-wrapper gates before
one newly authorized build.
