# REG2847 — C34L transition FIX2 uninstall static-ban false positive

Date: 17 August 2026
State: registered first PS7 lifecycle static-scan failure; zero external action

## Mistake

The first direct PS7 lifecycle suite after FIX2 integration rejected a broad
source substring ban for `uninstall`. The final OPPO evidence schema legitimately
contains `uninstallPerformed` and the transition validates it exactly false; the
static scan therefore produced a false positive before fixture transitions.
No retry or later mutation followed.

## Prevention

Replace broad action-word substring bans with executable-command/cmdlet call
anchors and behavioral zero-action assertions. Explicit false-valued evidence
properties such as `uninstallPerformed` must remain allowed and validated.
