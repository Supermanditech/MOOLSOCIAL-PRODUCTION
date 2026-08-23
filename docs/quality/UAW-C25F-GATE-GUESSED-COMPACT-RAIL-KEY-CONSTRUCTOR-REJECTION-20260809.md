# C25F gate guessed compact rail key constructor rejection

- Date: 2026-08-09
- Status: registered before gate retry

The first C25F machine gate required the exact source spelling `key: const ValueKey('moolsocial-compact-destination-rail')`. The production owner uses an equivalent key constructor/spelling, so the static string assertion failed before behavioral gates ran.

The correction reads the exact current source spelling and gates the stable key value without overfitting to `Key` versus `ValueKey` constructor syntax.
