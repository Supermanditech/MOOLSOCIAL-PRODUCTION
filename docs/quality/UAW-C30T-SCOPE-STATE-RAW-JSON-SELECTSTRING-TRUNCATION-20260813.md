# C30T scope-state raw JSON Select-String truncation

- Regression: `REG-20260813-1991-C30T-SCOPE-STATE-RAW-JSON-SELECTSTRING-TRUNCATION`
- Ticket: `UAW-C30T-PRE-AAB-FEED-AUTHOR-PROFILE-AND-FOLLOW-MISSING`
- Result: the truncated combined state read is rejected as sealing evidence.

The scope-state document was read as one raw string and passed to text matching.
Because the match belonged to the one whole-document record, PowerShell rendered
the large owner and exceeded the evidence channel. The corrected audit parses
JSON and projects only the exact selected assessment and checkpoint nodes.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
