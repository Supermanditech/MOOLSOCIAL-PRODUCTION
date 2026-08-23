# C30U build-wrapper stale patch context

Date: 2026-08-13
Regression: `REG-20260813-2013-C30U-BUILD-WRAPPER-MULTIHUNK-STALE-CONTEXT`

## Incident

The first attempt to generalize the single-AAB wrapper combined many distant
replacements. Two version-verification contexts did not match the exact script,
so `apply_patch` rejected the entire patch atomically. No wrapper change was
made.

## Permanent prevention

Read each exact release-control region immediately before editing and apply
small independent hunks.

This incident grants no additional authority.
