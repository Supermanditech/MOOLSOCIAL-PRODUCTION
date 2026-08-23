# C30B device-bounds string-concatenation tap rejection

- Regression: `REG-20260811-1358-C30B-DEVICE-BOUNDS-STRING-CONCATENATION-TAP-REJECTION`
- Date: 2026-08-11
- Scope: C30B OPPO founder-review positioning.
- Failure: captured bounds were concatenated as strings before conversion, so the tap coordinate was outside the display and Feed remained selected.
- Permanent prevention: cast each coordinate before arithmetic, validate the point against the source bounds/display, tap once, and verify selection from a new hierarchy.
