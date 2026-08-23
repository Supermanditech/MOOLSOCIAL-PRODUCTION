# C30T Dart separate Comment interface promotion assumption

- Regression: `REG-20260813-1964-C30T-DART-SEPARATE-COMMENT-INTERFACE-PROMOTION-ASSUMPTION`
- Date: 2026-08-13
- Scope: Comment/Reply source implementation.

## Incident

Focused analysis found two undefined-method errors because a value remained
statically typed as the base Social gateway after checking a separate optional
Comment interface.

## Required prevention

Resolve optional capabilities through an explicit nullable, correctly typed
adapter and invoke methods only on that adapter. Analyze before tests.

This record creates no build, upload, install, deployment or device authority.
