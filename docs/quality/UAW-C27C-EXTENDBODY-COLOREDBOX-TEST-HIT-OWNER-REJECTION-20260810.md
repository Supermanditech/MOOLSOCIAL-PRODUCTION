# C27C extendBody ColoredBox test-hit owner rejection

## Observation

The first C27C focused test mounted an opaque full-body `ColoredBox` in a
synthetic `Scaffold(extendBody: true)`. The test binding resolved the compact
Mool launcher's visual centre but hit-tested the extending body owner instead,
so the switcher did not open and the panel lookup failed.

## Cause

The visual-token test unnecessarily reproduced an extending content body even
though overlay/hit-order behavior is already covered by the production-family
tests and C26C interaction suite.

## Permanent prevention

Focused component tests use a non-extending Scaffold unless extending-body
ownership is itself the behavior under test. Real family integration and device
tests remain responsible for production extendBody combinations.

## Resolution evidence

The exact hit-test trace was retained before retry. The test harness will remove
only synthetic `extendBody: true`; runtime source is unchanged.
