# C20H multi-capture host invocation UIAutomator race rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

The Doctor evidence completed correctly. A Salon navigation and capture chained
in the same host invocation then reached two consecutive exact selected-state
confirmations, but the final remote UIAutomator hierarchy did not confirm Salon
and Book. The helper rejected the capture before any `15-book-salon` local file
was written.

## Prevention

Every accepted device state is now executed as a separate helper invocation.
Each retry starts with a fresh live inventory, waits for two exact semantic
confirmations, validates the final remote hierarchy, and only then pulls new
never-overwritten local evidence.
