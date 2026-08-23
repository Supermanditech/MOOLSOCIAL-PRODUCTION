# C30T Social consumer-owner path-guess recurrence

- Regression: `REG-20260813-1955-C30T-SOCIAL-CONSUMER-OWNER-PATH-GUESS-RECURRENCE`
- Date: 2026-08-13
- Scope: read-only owner discovery; no source mutation resulted.

## Incident

A grouped search included the guessed Social path
`apps/mobile/lib/ui_v2/social/social_v2_screen.dart`. The path does not exist,
so the nonzero grouped result and its otherwise displayed matches were rejected.

## Required prevention

Resolve exact Social implementation owners using a narrow current-tree filename
inventory before searching symbols. Any path error rejects the whole grouped
result.

This record creates no build, upload, install, deployment or device authority.
