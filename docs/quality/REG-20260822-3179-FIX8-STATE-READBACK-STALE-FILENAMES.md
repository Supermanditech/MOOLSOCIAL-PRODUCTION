# REG3179 - FIX8 state readback used stale filenames

## Classification

Registered read-only diagnostic path rejection with zero build, APK, install,
repository-state transition or device action.

## Evidence

A bounded consistency read used the nonexistent shorthand paths
`config/mvp-scope-state.json` and
`config/public-auth-provider-readiness-state.json`. PowerShell returned native
file-not-found errors. The same command independently proved the required
branch, HEAD and FIX8 ticket checksum; no deployment, build or device command
ran.

## Prevention

Use the authoritative owners `config/mvp-scope-gate-state.json` and
`config/public-auth-live-provider-readiness-state-c34p-fix5.json`, recovered
from a config-scoped exact filename inventory, before repeating the readback.
