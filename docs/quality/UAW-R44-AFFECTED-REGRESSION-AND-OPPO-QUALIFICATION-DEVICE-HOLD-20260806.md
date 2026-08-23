# UAW-R44 affected regression and OPPO qualification device hold

Date: 6 August 2026
Ticket: `UAW-R44-AFFECTED-REGRESSION-AND-OPPO-QUALIFICATION`
State: `DEVICE_HELD_NOT_SELECTED_NOT_EXECUTING`

## Disposition

R44 remains `mvp_required`, but its dependencies `ticket_43`,
`mvp_scope_gate` and `apk_machine_gate` are not satisfied for an exact R43
candidate. R43 is dependency-held, so there is no bounded source candidate,
unique build identity or checksum-matched APK to qualify.

The connected OPPO CPH2375 was checked read-only and remains authorized as an
ADB device. Connection alone is not build, install or test authority. The
protected `BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7` runtime and APK
identity remain outside this unselected ticket.

No build, install, launch, clear-data, input, screenshot, log capture or other
OPPO mutation was performed for R44. It will be reassessed after R43 produces a
scope-gated candidate and the APK machine gate authorizes an exact build/install
identity.

Next child by manifest order for founder-final disposition:
`UAW-R45-FOUNDER-CUMULATIVE-ACCEPTANCE-PACK`.
