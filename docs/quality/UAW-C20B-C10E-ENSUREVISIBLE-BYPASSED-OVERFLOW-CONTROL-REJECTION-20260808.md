# C20B C10E ensureVisible bypassed overflow control rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SUBACTION-DISCLOSURE-AND-OVERFLOW-AFFORDANCE-FIX3-C20B`

After the C10E selected-main assertions were reconciled, six of seven journeys
passed. The remaining deep Eat-to-Work journey called test-only
`ensureVisible` on `mool-action-work`, then tapped its center. The shared rail's
active-action synchronization retained Eat as the active visible owner, while
the Work render box remained beneath the reserved right-side overflow region.
The hit test landed on the `Next main actions` control and Work navigation did
not begin.

C20B intentionally provides that visible, 44x48, exact-semantics overflow
control as the real-user way to expose off-screen main actions. The historical
test must use `Next main actions` until Work is hit-testable and then tap Work;
it may not bypass the user contract with framework scrolling. No build,
install or OPPO mutation occurred.
