# C25F Fix1 Screen04 label assertion stale-context rejection

- Date: 2026-08-09
- Status: registered before retry

The first test correction patch used the pre-format multiline shape of the Screen04 choices assertion. Dart format had already changed that exact block, so `apply_patch` rejected the hunk and made no file change.

The retry reads the bounded current block and patches the smallest exact assertion.
