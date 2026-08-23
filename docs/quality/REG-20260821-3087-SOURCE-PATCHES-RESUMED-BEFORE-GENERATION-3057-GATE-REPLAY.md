# REG3087 — source patches resumed before generation-3057 gate replay

- Date: 2026-08-21
- Status: registered before testing

After REG3086 moved the registry to generation 3057, the bootstrap source
patches resumed before the updated regression, coordination and MVP gates were
replayed. No test, build, device or external action followed those patches.

Prevention: registry movement invalidates the prior execution pin; replay all
mandatory gates before the next source mutation or test, even when continuing
the same defect repair.
