# C16A adaptive-layout numeric type-inference rejection

## Incident

The first C16A focused Flutter test run stopped during compilation. In
`MoolLocalNavigationTokens.clusterWidth`, `math.max(0, maxWidth - inset)`
inferred `num`, which could not be passed to the following `double` expression.
No test executed and no device, build or runtime state changed.

## Root cause and prevention

An integer zero literal was mixed with double layout operands. Shared layout
math uses double literals throughout (`0.0`) and the focused design-owner test
must compile and pass before any destination-conformance ticket opens.
