# C30T fingerprint oversized inline-command failure

Date: 2026-08-13
Regression: `REG-20260813-2004-C30T-FINGERPRINT-OVERSIZED-INLINE-POWERSHELL-LAUNCH-FAILURE`

## Incident

The first read-only current-source fingerprint calculation was issued as one
oversized inline PowerShell command. The shell host rejected process launch
with `Access is denied`. No result was accepted and no project file was changed
by that failed calculation.

## Permanent prevention

Complex multi-owner qualification calculations must be implemented as a
bounded, reviewable audit script added through `apply_patch`, then executed
read-only. They must not be compressed into an oversized shell argument.

This incident grants no AAB, upload, install, deployment, or device authority.
