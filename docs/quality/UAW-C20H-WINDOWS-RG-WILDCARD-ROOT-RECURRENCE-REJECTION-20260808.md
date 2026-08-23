# C20H Windows rg wildcard-root recurrence

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

A device-helper lookup passed `docs/quality/UAW-C17H-*` as a positional
ripgrep root. Windows rejected that root as an invalid filename. Although a
second literal artifact root returned the predecessor helper path and its
`y=1480` transform, the combined search is not admitted as complete evidence.

## Prevention

The next action reads the returned literal helper path directly. All later
Windows searches use literal roots and `-g` for filename patterns. This is a
recurrence of the permanent wildcard-root rule and made no source, APK or device
change.
