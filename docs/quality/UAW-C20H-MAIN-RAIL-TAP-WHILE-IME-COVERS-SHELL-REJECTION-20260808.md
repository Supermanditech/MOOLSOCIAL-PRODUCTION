# C20H main-rail tap while IME covers shell rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

Social/Create auto-focused its composer and displayed the Android keyboard. The
saved Create screenshot visibly shows the IME covering the local and global
rails. A subsequent `Open Buy` physical-rail tap therefore hit the IME region;
fresh semantics correctly remained Social/Create. No Buy evidence was saved.

## Prevention

The matrix now checks IME visibility before every global navigation action. One
system Back may dismiss the keyboard only; the exact Social/Create state must
remain selected in two fresh hierarchies and a rail-visible screenshot must be
captured before any family navigation tap.
