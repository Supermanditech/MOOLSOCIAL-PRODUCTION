# REG2634 — C33T MVP state relative path resolved against caller CWD

Date: 2026-08-16 IST

## Incident

The founder invoked the presealed C33T r60.58 launcher from the existing visible
`C:\WINDOWS\system32` Windows PowerShell prompt. The launcher entered PowerShell
7.6.5 and proved its founder-owned visible console. The C33G FIX4 prebuild gate
passed, then the MVP scope gate stopped the C33T build gate with:

`MVP scope gate rejected: machine state must stay inside the production repository.`

No hidden prompt was shown. No founder input was entered or observed. No
transient define or Google Services file was created. C33T action counts stayed
`0/0/0/0` and its build result stayed `not_started`.

## Root cause

`scripts/check-mvp-scope-gate-state.ps1` called
`[IO.Path]::GetFullPath($StatePath)` directly. When `StatePath` was
repository-relative, PowerShell resolved it against the caller's current
directory instead of the explicit normalized `RepositoryRoot`.

## Permanent prevention

Relative MVP state paths must first be joined to the explicit repository root;
absolute paths remain subject to the existing repository-prefix boundary. The
corrected owner must be exercised from outside the repository in both
PowerShell 7 and Windows PowerShell before an exact successor is sealed.

C33T is permanently rejected before prompts and build. It must not be retried.
