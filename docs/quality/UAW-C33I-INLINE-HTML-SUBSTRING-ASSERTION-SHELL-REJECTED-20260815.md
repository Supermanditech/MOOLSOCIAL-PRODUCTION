# C33I inline HTML-substring assertion shell rejection

Date: 2026-08-15
Ticket: `UAW-C33I-SCREEN03-PASSWORDLESS-EMAIL-LINK-REFERENCE-SUCCESSOR`

## Failure

A serial PowerShell check attempted to load the full proposal, slice the choose-state substring and evaluate several regex assertions. The host rejected the command with `Access is denied` before any result. The prior serial `rg` provider-count command completed successfully. No file was changed.

## Root cause

The audit retained an inline full-file substring/regex execution shape that the shell host rejected, despite removing concurrency.

## Permanent prevention

For this proposal, use serial bounded `rg` exact-anchor checks and direct hashes only. Do not retry inline full-file substring execution; an exact unexpected anchor such as `Welcome` is checked with an explicitly normalized no-match command.
