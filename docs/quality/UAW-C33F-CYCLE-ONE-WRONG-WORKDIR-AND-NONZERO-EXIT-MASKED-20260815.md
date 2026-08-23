# UAW C33F cycle-one wrong workdir and nonzero exit masked

Date: 2026-08-15
Regression: `REG-20260815-2366-C33F-CYCLE-ONE-WRONG-WORKDIR-AND-NONZERO-EXIT-MASKED`

The first C33F cycle-one command set used `apps/mobile` as its tool working directory while invoking repository-relative `scripts/...` and `tmp/...` paths. Six pre-gates were therefore not found. PowerShell continued because each `pwsh -File` process failure was not checked immediately, and the final whole-mobile analyzer passed, leaving the overall shell exit code at zero. The attempt is invalid and is not counted as a qualification cycle. No Flutter tests, build, upload, device, provider or external action occurred.

Recovery: register before retry. Run orchestration from repository root, invoke every repository gate with an exact repository-relative path, check `$LASTEXITCODE` immediately after every native child process, and use `Push-Location` only around `flutter analyze`. Restart cycle 1 from its immutable-manifest comparison; the standalone analyzer pass is diagnostic evidence only.
