# Post-seal C17D/C21E remaining-family glass contract failure

The individually executed C21E matrix owner
`mool_remaining_family_clear_glass_conformance_c17d_test.dart` produced
0 passes and 10 failures.

- Nine Eat/Ride/Book/Work selected-state cases expected the compact cluster
  centered at x=206 in a 412-pixel rail; current left-anchored clusters center
  at x=76 for two actions and x=116 for three actions.
- The inventory case expected 200/268-pixel two/three-action clusters; current
  `MoolLocalNavigationTokens.clusterWidth` returns 152/232.

This result is separate from C20E's 1-pass/5-fail result and from the green
current Eat suites. REG-2300 must be registered before retry. C17D/C21E must be
compared with the later accepted local-destination rail authorities before any
test migration; production geometry must not be regressed merely to satisfy a
historical matrix.
