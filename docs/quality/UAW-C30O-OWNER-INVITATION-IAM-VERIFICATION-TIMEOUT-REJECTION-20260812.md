# C30O Owner-invitation IAM verification timeout rejection

Date: 2026-08-12

## Observed mistake

The read-only IAM verification for `user:supermanditech@gmail.com` did not return within the command timeout and produced no policy rows.

## Root cause

The Cloud IAM read stalled at the external CLI/service boundary; the dashboard screenshot alone cannot distinguish `roles/browser` access from an accepted `roles/owner` invitation.

## Prevention

- Do not treat project-dashboard visibility as proof of Owner acceptance.
- Retry only one narrower, read-only IAM query with a bounded longer timeout.
- Do not submit another Play link until the actual `roles/owner` binding is observed.

## Retained evidence

The tool result records exit code 124 after 34 seconds. No Cloud or Play write occurred.
