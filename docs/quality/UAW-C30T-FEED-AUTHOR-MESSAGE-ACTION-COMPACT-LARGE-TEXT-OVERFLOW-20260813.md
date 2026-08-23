# C30T Feed author Message action compact large-text overflow

- Regression: `REG-20260813-1984-C30T-FEED-AUTHOR-MESSAGE-ACTION-COMPACT-LARGE-TEXT-OVERFLOW`
- Ticket: `UAW-C30T-PRE-AAB-FEED-AUTHOR-PROFILE-AND-FOLLOW-MISSING`
- Focused result: 34 passed, 1 failed; run rejected.

At 320px and 140-percent text, a real authorId rendered the trailing labeled
`Message` action in the Feed card and overflowed the author header by 3.6
pixels. Compact/enlarged layouts must use a semantic tooltip-backed icon action
with the same key and behavior.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
