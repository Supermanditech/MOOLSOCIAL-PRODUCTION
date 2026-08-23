# C30T authoritative Flutter compact reporter truncation

- Regression: `REG-20260813-2000-C30T-AUTHORITATIVE-FLUTTER-COMPACT-REPORTER-TRUNCATION`
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Result: the compact reporter run is rejected as cumulative qualification evidence.

The authoritative 58-file manifest exited zero and showed a 401-pass, 3-skip
ending, but compact progress carriage returns expanded beyond the evidence
channel. The exact manifest must be replayed using an in-memory JSON reporter
parser that emits only counted totals and the preserved process exit.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
