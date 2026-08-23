# C30T optional duplicate-ticket no-match exit recurrence

- Regression: `REG-20260813-1998-C30T-OPTIONAL-DUPLICATE-TICKET-NO-MATCH-EXIT-RECURRENCE`
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Result: the raw optional absence query is rejected as duplicate-search evidence.

The duplicate ticket filename check repeated REG-1997's optional no-match exit
mistake immediately after the prevention rule was added. The corrected command
must label and normalize only ripgrep exit 1 while preserving all real errors.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
