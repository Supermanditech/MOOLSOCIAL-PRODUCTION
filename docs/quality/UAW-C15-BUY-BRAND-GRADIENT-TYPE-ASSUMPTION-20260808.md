# C15 Buy brand-gradient type assumption

Date: 2026-08-08

Regression ID:
`REG-20260808-298-C15-BUY-BRAND-GRADIENT-TYPE-ASSUMPTION`

The first isolated Buy analyzer after adding a background canvas rejected one
line: `surfaceTheme.canvasGradient` has type `MoolBrandGradient`, while Flutter
`BoxDecoration.gradient` requires `Gradient`. No runtime test, build or device
step followed the analyzer failure.

Root cause: a repository-owned semantic gradient enum was assumed to be a
Flutter rendering gradient without inspecting its declaring owner first.

Permanent prevention: inspect the exact declared design-token type before
composition. A `MoolBrandGradient` is rendered through the existing
`MoolFiniteGradientTransition` or an explicit `LinearGradient` made from its
authoritative `.colors`; it is never cast or passed directly to a Flutter
`Gradient` parameter. Focused analysis precedes test replay.
