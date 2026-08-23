# C24C nonexistent XXXL spacing-token rejection — 2026-08-09

The first affected-source analyzer rejected two C24C bottom insets because
`MoolSpacing.xxxl` is not part of the production design-system scale. The scale
ends at `MoolSpacing.xxl`; the invalid references also made the surrounding
constant edge insets non-constant.

REG638 preserves the mistake. Both Eat discovery owners now use the existing
`MoolSpacing.xxl` token, and affected-source analysis is required before any
focused widget-test attempt.
