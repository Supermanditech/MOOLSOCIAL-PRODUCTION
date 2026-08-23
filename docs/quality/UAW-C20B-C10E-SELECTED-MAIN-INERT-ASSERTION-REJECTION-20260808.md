# C20B C10E selected-main inert assertion rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SUBACTION-DISCLOSURE-AND-OVERFLOW-AFFORDANCE-FIX3-C20B`

The seven-file C20B compatibility shard completed 63 passing cases and seven
rejections, all in
`uaw_personal_mvp_global_navigation_motion_containment_c10e_test.dart`.
Each rejection came from the shared `expectSelectedWithoutTap` helper and used
the message that the selected main destination must be inert. The affected
selected families were Social, Eat, Ride, Book and Work across the existing
motion/ownership journeys.

C20B intentionally replaces that historical inert state with the founder-
requested explicit Hide/Show owner on the already selected main action. Its
tap changes only local rail visibility; it does not navigate, add history,
reset content or disturb the anchored global shell. All other compatibility
files in the shard continued to pass. No build, install or OPPO mutation
occurred.

The C10E helper must preserve its selected-state and one-shell assertions but
now require a semantic tap action and exact current Hide-family-options label.
The existing C20B focused test remains the owner for proving that the tap
collapses/restores without main navigation or history mutation.
