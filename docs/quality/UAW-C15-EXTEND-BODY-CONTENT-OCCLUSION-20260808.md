# C15 extend-body content occlusion

Date: 2026-08-08

Regression ID:
`REG-20260808-297-C15-EXTEND-BODY-CONTENT-OCCLUSION`

After the transparent-wave focused matrix passed, the first final-state
Eat/Ride/Book/Work vertical cycle rejected 26 journeys. The six destination
Scaffolds extended their bodies behind the navigation, but their body
`SafeArea` widgets had also been changed to `bottom: false`. Existing primary
controls were therefore laid out beneath the 92px local-plus-global navigation
stack. One retained diagnostic reported Ride's `ride-book` target at y=883,
outside the hittable destination viewport.

Root cause: visual canvas continuation and interactive content insetting were
treated as the same layer. Extending the background does not authorize placing
buttons, grids or final scroll content under fixed navigation.

Permanent prevention: destination Scaffolds may use `extendBody: true` so the
canvas remains visible behind the transparent wave, but body `SafeArea` keeps
bottom protection enabled. Buy supplies its destination gradient behind that
safe content layer. The complete Eat/Ride/Book/Work and Buy functional suites
must pass twice after this composition settles.
