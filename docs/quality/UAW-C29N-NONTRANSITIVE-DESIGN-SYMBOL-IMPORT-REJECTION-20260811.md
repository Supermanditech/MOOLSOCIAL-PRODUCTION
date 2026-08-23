# C29N non-transitive design-symbol import rejection

Date: 2026-08-11
State: resolved; permanent prevention active
Regression: `REG-20260811-1231-C29N-NONTRANSITIVE-DESIGN-SYMBOL-IMPORT-REJECTION`

Focused analysis of the rewritten C16B Social successor test rejected an
undefined `MoolLocalNavigationRail`. The test imported the global-navigation
library, but Dart does not re-export that library's own design-system import.
No tests or host cycle ran. The test now directly imports the declaring design
library, and focused analysis remains mandatory before qualification.
