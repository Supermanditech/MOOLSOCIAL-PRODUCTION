# C30T validator read stale range and optional ripgrep compound failure

- Regression: `REG-20260813-1997-C30T-VALIDATOR-READ-STALE-RANGE-OPTIONAL-RG-COMPOUND-FAILURE`
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Result: the failed combined diagnostic is rejected as validation evidence.

The exact validator symbol was located at line 803, but the subsequent read
used a stale later range. A separate optional test-text search returned no match
and made the combined command nonzero. The corrected audit reads the exact
validator range and treats optional absence independently.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
