# C30T Flutter JSON optional property assumption

Date: 2026-08-13
Regression: `REG-20260813-2007-C30T-FLUTTER-JSON-OPTIONAL-HIDDEN-PROPERTY-ASSUMPTION`

## Incident

The bounded authoritative Flutter JSON parser ran with strict mode and accessed
`test.hidden` directly. Some valid `testStart` events omit that optional field,
so the parser failed after Flutter finished. The run is rejected as cumulative
qualification evidence.

## Permanent prevention

Optional reporter protocol fields must be accessed through explicit
property-existence helpers with documented defaults. Strict mode remains
enabled; any parser exception invalidates that run before retry.

This incident grants no AAB, upload, install, deployment, or device authority.
