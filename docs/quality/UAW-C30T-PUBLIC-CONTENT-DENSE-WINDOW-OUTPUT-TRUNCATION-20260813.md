# C30T public-content dense-window output truncation

- Regression: `REG-20260813-1953-C30T-PUBLIC-CONTENT-DENSE-WINDOW-OUTPUT-TRUNCATION`
- Date: 2026-08-13
- Scope: diagnostic verification only; no source mutation resulted from the
  failed inspection.

## Incident

A verification read requested roughly 190 dense lines from
`apps/mobile/lib/ui_v2/social/social_v2_public_content.dart`. The returned
output was truncated and therefore could not prove that the partially added
quoted-post widget remained at a valid top-level Dart location.

## Required prevention

Dense Dart owners are read only in exact, non-overlapping windows of at most
100 lines. Truncated reads are inadmissible and must be registered before a
smaller-window retry.

This record creates no build, upload, install, deployment or device authority.
