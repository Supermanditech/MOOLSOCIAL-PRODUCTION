# C10E postbuild protected Screen 01 guessed-path recurrence

- Registry: `REG-20260807-236-C10E-POSTBUILD-PROTECTED-SCREEN01-GUESSED-PATH-RECURRENCE`
- State: resolved; permanent gate active.

The postbuild source-drift command correctly proved the 240-file authored
runtime aggregate, then guessed a shortened protected Screen 01 path and failed
before the protected-path and `git diff --check` portions. This repeated the
class already registered by REG215: using a remembered operand rather than a
bounded exact inventory. No artifact finalization or device mutation occurred.

The exact owner is
`apps/mobile/lib/ui_v2/screens/screen01_app_splash/app_splash_screen_v2.dart`,
discovered by a bounded `rg --files apps/mobile/lib` inventory. Postbuild
protected checks use that literal path and remain separate from already passed
runtime aggregate checks.
