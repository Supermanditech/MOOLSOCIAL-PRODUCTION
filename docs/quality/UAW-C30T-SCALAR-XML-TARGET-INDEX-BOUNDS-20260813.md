# C30T scalar XML target/index bounds rejection

- Date: 2026-08-13
- Device: OPPO CPH2375, serial `2b3e0f71`
- Installed artifact: Google Play Internal Testing `1.0.0-r60.44 (2026081244)`
- Scope: read-only/non-writing Create-format journey inventory

The normalized Quiz-format retry correctly identified one enabled clickable semantic XML element, but the filtered PowerShell pipeline was stored as a scalar and then indexed as if it were an explicit array. The bounds assertion stopped the operation before any tap.

A read-only inspection subsequently proved the authoritative node is an `XmlElement`, its bounds value is the string `[540,1288][704,1400]`, and its normalized description is `Quiz / Quiz`. No UI action, Create write, backend write, build, upload or install occurred.

The next retry must wrap the complete filtered pipeline in an explicit array, require exactly one target, cast bounds to string, validate the exact coordinate shape, cast all four capture groups independently to integers, and derive the tap centre only from that same fresh hierarchy.
