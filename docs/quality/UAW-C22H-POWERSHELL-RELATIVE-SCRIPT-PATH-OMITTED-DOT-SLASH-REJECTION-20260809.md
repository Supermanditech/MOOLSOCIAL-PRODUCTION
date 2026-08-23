# C22H PowerShell relative-script invocation rejection

- Date: 2026-08-09
- Scope: C22H prebuild validation only
- Device mutation: none
- APK build/install mutation: none

## Rejection

The first aggregate validation parsed `config/apk-regression-gate-state.json`
successfully, then stopped because PowerShell did not resolve
`scripts/check-delivery-lock.ps1` from the current directory. The attempted
name was also not the verified delivery-lock owner. No later gate in that
aggregate ran, so the command supplied no build or install authority.

## Prevention

Discover the exact gate owner from the bounded repository inventory and invoke
it through `./scripts/...` (or a verified literal absolute path). Any stopped or
partial aggregate is rejected in full before retry.
