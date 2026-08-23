# C21F formatter-fragile default-expanded gate rejection — 2026-08-08

The first C21F machine-gate run chained and passed C21B, C21C, C21D and C21E, then rejected the valid default-expanded implementation because the gate searched for the exact adjacent text `?? true`. Dart formatting had placed whitespace and a line break between those tokens. Static analysis and all ten focused disclosure tests had already passed, including all-six-family default expansion.

The failed gate result is rejected and is not qualification evidence. REG-20260808-486 requires whitespace-tolerant structural matching plus the existing behavioral test before retry. No APK build, install or OPPO mutation occurred; installed r60.19 identity remains preserved.
