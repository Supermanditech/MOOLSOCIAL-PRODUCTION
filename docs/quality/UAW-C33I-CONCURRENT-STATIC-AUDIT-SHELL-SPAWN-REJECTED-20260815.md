# C33I concurrent static-audit shell-spawn rejection

Date: 2026-08-15
Ticket: `UAW-C33I-SCREEN03-PASSWORDLESS-EMAIL-LINK-REFERENCE-SUCCESSOR`

## Failure

After splitting the static audit, three read-only shell checks were launched concurrently. The Windows host rejected the aggregate launch with `Access is denied` before any result was returned. No file was changed.

## Root cause

The correction removed command monolith size but retained concurrent Windows process launches, leaving a second host-level rejection surface.

## Permanent prevention

Run C33I post-correction shell checks strictly one process at a time. Do not use parallel shell launches for this audit; accept evidence only from an individually completed exit-zero command.
