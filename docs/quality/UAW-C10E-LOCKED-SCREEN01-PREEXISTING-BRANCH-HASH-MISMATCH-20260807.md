# UAW C10E pre-existing locked Screen 01 branch hash mismatch

- Registry: `REG-20260807-216-C10E-LOCKED-UI-PREFLIGHT-FAILED-ON-CLEAN-BRANCH-BASELINE-FILE`
- State: external pre-existing rejection; C10E constrained away from the locked dependency graph
- Detection: `check-approved-ui-locks.ps1` expected SHA-256 `B0E7B099B70BE7240A4E7699596AB7F16B77285FBA9C23C4F3708AFDA7AE218D` for `app_splash_screen_v2.dart` but the remediation branch contains `D08DBA928B884554984D28891F5E465B1F7FA910D3884EBE49B6466D199147BE`.
- Reconciliation: path-scoped `git status` is empty and `git diff --exit-code` against HEAD returns 0, proving this is committed branch-baseline state rather than a C10E or current dirty-workspace edit.
- Durable prevention: do not modify, normalize, restore or re-hash the protected file. C10E must not change boot/setup/sign-in routes or a global router transition that affects them; it uses only the existing global dock and supported app-page scaffolds. Record a before/after path hash and retain the independent repository-lock rejection truthfully.
- Boundary: resolving the accepted-reference mismatch requires a separate authorized locked-reference reconciliation and is not silently included in navigation work.
- Postflight: after C10E implementation, two 229-test affected cycles and all independent host gates, path-scoped tracked status remains empty, `git diff --exit-code` against HEAD remains 0 and SHA-256 remains `D08DBA928B884554984D28891F5E465B1F7FA910D3884EBE49B6466D199147BE`. The protected file was not touched.
