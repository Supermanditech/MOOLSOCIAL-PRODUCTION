# C20H unhandled rg no-match exit rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

A read-only final-gate lookup found no matching invocation text. Ripgrep's
normal exit code `1` for no matches was allowed to fail the surrounding shell
call. No gate result was inferred. The retry uses no-match-safe discovery and
directly reads the authoritative gate records.
