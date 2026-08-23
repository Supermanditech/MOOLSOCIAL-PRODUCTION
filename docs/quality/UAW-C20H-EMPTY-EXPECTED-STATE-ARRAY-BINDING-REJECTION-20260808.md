# C20H empty expected-state array binding rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

After an `Open Social` tap, the inventory-only helper unconditionally called
its selected-state wait function with an empty expected-state array. PowerShell
rejected the mandatory array binding before inventory output. No screenshot or
named destination evidence was saved.

## Prevention

The helper now invokes selected-state waiting only when at least one exact live
semantic is supplied. Inventory-only actions always print the fresh post-tap
state, which must then be used for a separate two-confirmation capture.
