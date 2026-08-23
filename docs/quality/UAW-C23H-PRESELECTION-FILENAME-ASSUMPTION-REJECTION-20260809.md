# C23H preselection filename assumption rejection — 2026-08-09

## Observed rejection

The C23H audit guessed that its preselection evidence name matched the ticket
manifest wording. That file did not exist, so the read-only batch stopped
before APK-state and OPPO reconciliation. No ticket or device state changed.

## Permanent prevention

Inventory bounded `docs/quality/*C23H*` files and use only the literal owner
returned by that inventory. Ticket and evidence filenames are independently
discovered.
