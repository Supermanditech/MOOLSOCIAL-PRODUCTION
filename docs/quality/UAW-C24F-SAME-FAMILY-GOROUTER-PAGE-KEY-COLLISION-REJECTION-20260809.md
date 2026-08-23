# C24F same-family GoRouter page-key collision rejection — 2026-08-09

The first history-preserving correction pushed every connected action. In the
Screen04 real-router sequence, repeated Social subaction routes share the same
GoRoute owner and differ by query state. Stacking them produced duplicate
Navigator page keys. The initial collision contaminated the remainder of that
test file, accounting for the 16 reported failures; a single isolated fitment
case passes.

The production correction distinguishes route intent. A cross-family action
pushes so system Back restores the prior family. A same-family action replaces
only the current top page, preventing duplicate route keys while retaining any
cross-family page beneath it. Both behaviors require focused and complete-suite
proof before either protected successor seal can be created.
