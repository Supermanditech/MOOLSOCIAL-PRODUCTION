# Post-C32P MVP scope-state path assumption

Date: 15 August 2026
Regression: `REG-20260815-2268-POST-C32P-MVP-SCOPE-STATE-PATH-ASSUMPTION`

The first post-failure evidence probe attempted to read `config/mvp-scope-state.json`, which does not exist. The failed read did not change source, configuration, device or external state.

The retry must discover the exact scope and ticket state paths from the bounded `config` inventory before reading them. The guessed path must not be retried.
