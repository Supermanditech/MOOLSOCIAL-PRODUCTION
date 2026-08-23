# Ride four-action compact rail minimum-width assertion

The preserved C16E focused run is a real `0/2` failure. At a `320x568`
logical surface with text scale `1.4`, both the contextual-selection case and
the reduced-motion case fail while building the shared local-navigation
`LayoutBuilder`.

`MoolLocalNavigationTokens.clusterWidth` requires four 44-pixel actions plus
compact gaps and asserts that at least 182 logical pixels remain after its own
horizontal insets. `MoolDestinationNavigationV2` also reserves the global
Mool, Ride-family-root and Chat controls in the same destination row, so the
Ride rail receives less than that minimum and throws before its compact
cluster is available.

This is a current compact-layout defect, not proof of provider integration or
device qualification. REG-2308 blocks any unchanged retry. A separately
selected MVP successor must preserve 44-pixel local targets, the three global
controls, reduced-motion behavior and in-place Ride selection without adding
routes, providers, maps, funds or external-service work.
