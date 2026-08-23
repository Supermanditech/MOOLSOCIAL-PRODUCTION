# C33I post-FINAL broad test-status output truncation

Date: 2026-08-15
Ticket: `UAW-C33I-SCREEN03-PASSWORDLESS-EMAIL-LINK-REFERENCE-SUCCESSOR`

## Failure

The first post-`FINAL` repository identity check included the entire `apps/mobile/test` directory in a targeted `git status`. The large dirty evidence tree caused output truncation, although the required branch and HEAD were still confirmed. No file was changed.

## Root cause

A broad directory was treated as a bounded status target in a repository with extensive user-owned test evidence.

## Permanent prevention

Post-`FINAL` status checks name only exact files modified by the active ticket. Directory-level status of `apps/mobile/test` is prohibited; use `rg --files` to resolve the exact intended test owners first.
