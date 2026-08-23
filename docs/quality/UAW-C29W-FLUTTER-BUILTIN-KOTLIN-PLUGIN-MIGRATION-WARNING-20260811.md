# C29W Flutter Built-in Kotlin plugin migration warning

- Date: 2026-08-11
- Candidate: `1.0.0-r60.35` (`2026081135`)
- Build result: succeeded
- APK SHA-256: `D664C8654D37188708795828F525433AFFA93BE8FBDC8CF3462178AAA1967E3E`

Flutter reported a forward-looking warning that several third-party plugins still apply the Kotlin Gradle Plugin and a future Flutter version will require Built-in Kotlin migration. This did not fail or alter the r60.35 build. The sealed candidate is preserved. Any plugin/toolchain migration is dependency-held for a separate ticket with official changelog review and two fresh Android qualification cycles; it is not mixed into C29W.
