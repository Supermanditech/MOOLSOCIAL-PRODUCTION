# UAW C33G FIX1 interpolating Dart source needle

Pre-execution review found that the first C33G FIX1 gate used a double-quoted PowerShell string containing the Dart expression `${_socialProviderLabel(provider)}`. PowerShell would interpolate that token instead of testing the literal Dart source.

The gate was never executed in that form. The correction uses a single-quoted regular expression with escaped Dart punctuation and is registered before the first gate run.
