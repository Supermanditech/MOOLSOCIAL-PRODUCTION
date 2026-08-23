# UAW C33J FIX2 optional Gradle owner guessed

- Regression: `REG-20260815-2512-C33J-FIX2-OPTIONAL-GRADLE-OWNER-GUESSED`
- Failure: the inventory read the real `build.gradle.kts`, then also requested
  a guessed `build.gradle` alternative and ended nonzero.
- Prevention: discover and read only the exact repository Gradle owner.
- Impact: no product or external state changed.
