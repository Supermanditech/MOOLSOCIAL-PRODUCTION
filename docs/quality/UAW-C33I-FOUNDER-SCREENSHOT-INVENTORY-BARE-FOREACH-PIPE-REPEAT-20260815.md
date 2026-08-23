# C33I founder-screenshot inventory bare-foreach pipe recurrence

Date: 2026-08-15
Ticket: `UAW-C33I-SCREEN03-PASSWORDLESS-EMAIL-LINK-REFERENCE-SUCCESSOR`

## Failure

The first founder-screenshot dimension/hash inventory placed a statement-form PowerShell `foreach` directly before `Format-Table`. PowerShell rejected the empty pipe element before reading or copying any image.

## Root cause

The command repeated `REG-20260815-2468-UI-READING-INVENTORY-BARE-FOREACH-PIPE` instead of applying its required named-array pattern.

## Permanent prevention

Every PowerShell inventory assigns loop output to an explicit ticket-named array, then pipes that array. For this retry use `$c33iScreenshotFacts = foreach (...) { ... }` followed by `$c33iScreenshotFacts | Format-Table`.
