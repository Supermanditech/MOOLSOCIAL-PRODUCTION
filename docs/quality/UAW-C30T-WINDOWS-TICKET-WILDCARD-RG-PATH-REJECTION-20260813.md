# C30T Windows ticket wildcard ripgrep path rejection

- Regression: `REG-20260813-1993-C30T-WINDOWS-TICKET-WILDCARD-RG-PATH-REJECTION`
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Result: the combined wildcard lookup is rejected as ticket evidence.

The bounded filename inventory returned the exact mobile and email OTP ticket
owners, but the follow-up content search still used a Windows wildcard path.
Ripgrep exited nonzero. Subsequent reads use only the exact discovered files.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
