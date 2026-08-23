# REG-20260816-2610 — C33N static-cycle composition used unverified interfaces and masked native exits

Date: 2026-08-16 IST

The first attempted C33N cycle-1 static composition is not counted. It tried
to reuse the immutable source-manifest writer as a read-only comparator, passed
an unsupported `TicketPath` parameter to the delivery gate, and guessed a UI
lock checker filename that does not exist. Because these checks were invoked
as native child PowerShell processes, the parent continued and finally exited
zero after the later dual-host C33N gates passed. That final exit does not make
the earlier failures successful.

Before retry, each checker path and parameter contract must be read literally.
The immutable manifest must be checked with a read-only hash/current-owner
comparison, and every native child exit code must be asserted immediately so a
later success cannot mask an earlier failure. No Flutter/backend/web cycle was
started, no build or external action occurred, and C33N remains `0/0/0/0`.
