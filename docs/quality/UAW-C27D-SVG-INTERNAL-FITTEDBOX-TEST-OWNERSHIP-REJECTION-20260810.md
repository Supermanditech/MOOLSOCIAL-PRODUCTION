# C27D SVG internal FittedBox test-ownership rejection

The first C27D real-route conformance run rejected Social because its broad
rail-descendant query found two `FittedBox` widgets. Those widgets belong to
the approved provider SVG rendering path; no destination label is wrapped in
or scaled by a `FittedBox`.

The forbidden regression is adaptive label shrinking, not SVG's internal
contain-fit implementation. C27D therefore proves that every shared
`MoolDestinationIconLabel` owns a direct two-line `Text` with the fixed Inter
token and separately proves all control geometry. The permanent component
gate continues to reject a production label `FittedBox` owner.
