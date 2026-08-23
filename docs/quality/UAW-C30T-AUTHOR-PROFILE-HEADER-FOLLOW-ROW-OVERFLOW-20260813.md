# C30T author profile header Follow row overflow

- Regression: `REG-20260813-1980-C30T-AUTHOR-PROFILE-HEADER-FOLLOW-ROW-OVERFLOW`
- Ticket: `UAW-C30T-PRE-AAB-FEED-AUTHOR-PROFILE-AND-FOLLOW-MISSING`
- Focused result: author guest journey failed with an 18-pixel right overflow.

The author sheet put avatar, identity metrics and the guest `Sign in to follow`
action in one horizontal row. The correction keeps identity in a flexible row
and stacks the relationship action below it at full width.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
