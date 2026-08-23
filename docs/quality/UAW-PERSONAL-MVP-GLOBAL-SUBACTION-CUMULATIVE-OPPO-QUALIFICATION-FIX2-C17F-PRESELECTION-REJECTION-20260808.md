# C17F preselection rejection — protected Screen 01 UI lock

Date: 2026-08-08
State: `preselection_rejected_build_install_closed`

## Qualified predecessor state

- C17E passed two consecutive unchanged-source host cycles: 591/591 tests per cycle, 1,182 total.
- Qualified fingerprint: `91D51D5C7AE7A45C08F649DE47FBEBA1E8E36C21D1572295A39C5C8B06425D41` over `apps/mobile/lib`, `apps/mobile/test`, and `scripts`.
- Branch: `remediation/prototype-conformance-2026-07-20`.
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`.
- C17F build authorization had not been opened when preselection checks began.

## OPPO preservation proof

- Sole connected device: serial `2b3e0f71`, model `CPH2375`.
- Installed package: `com.moolsocial.app`.
- Installed version: `1.0.0-r60.16`, code `2026080816`.
- First install time: `2026-08-04 02:51:59`.
- Last update time: `2026-08-08 14:20:42`.
- Live installed-base SHA-256: `1CC2A0186CA5DC8C9A09D0B4CC949B94CEE91DE6C70246A4B0168ADE6255150D`.

No uninstall, data clear, downgrade, install, package mutation, or device-state replacement was performed.

## Material gate rejection

The independent read-only command `scripts/check-approved-ui-locks.ps1` returned exit code 1 before any C17F authorization or build:

- Protected owner: `apps/mobile/lib/ui_v2/screens/screen01_app_splash/app_splash_screen_v2.dart`.
- Immutable accepted lock expected SHA-256: `B0E7B099B70BE7240A4E7699596AB7F16B77285FBA9C23C4F3708AFDA7AE218D`.
- Current branch-baseline SHA-256: `D08DBA928B884554984D28891F5E465B1F7FA910D3884EBE49B6466D199147BE`.
- Exact protected-path `git status --short --untracked-files=no`: empty; C17 made no worktree change to the file.

This is the previously registered branch-baseline blocker `REG-20260807-216-C10E-LOCKED-UI-PREFLIGHT-FAILED-ON-CLEAN-BRANCH-BASELINE-FILE`. It predates C17 and is outside the founder-authorized six-family subaction scope.

## Required disposition

- C17F is not selected.
- Successor build authorization remains unopened.
- No APK is built or installed.
- The protected lock is not weakened, bypassed, reclassified, or treated as an expected pass.
- Screen 01 and its accepted reference are not changed under C17.
- The next eligible action is a separately founder-authorized protected Screen 01 lock/reference reconciliation. After that resolves, C17F preselection must be rerun; any change inside the qualified fingerprint scope requires two fresh unchanged-source C17E cycles.

Founder device acceptance remains pending.
