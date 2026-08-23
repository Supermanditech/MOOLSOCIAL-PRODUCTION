# C30T full untracked Git status truncation

Date: 2026-08-13
Regression: `REG-20260813-2008-C30T-FULL-UNTRACKED-GIT-STATUS-WARNING-TRUNCATION`

## Incident

Final Git reconciliation requested `status --untracked-files=all` across the
founder's enormous evidence tree. Git streamed historical browser-artifact
long-path warnings, and the evidence result was truncated. Its dirty counts are
rejected. No file was changed or removed.

## Permanent prevention

Use exact branch and HEAD commands plus `git status --untracked-files=no` for
bounded tracked reconciliation. Never scan the established user-owned
untracked evidence tree merely to count it.

This incident grants no AAB, upload, install, deployment, or device authority.
