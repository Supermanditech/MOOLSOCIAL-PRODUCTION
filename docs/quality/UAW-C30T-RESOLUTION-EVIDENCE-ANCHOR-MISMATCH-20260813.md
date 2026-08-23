# C30T resolution evidence anchor mismatch

Date: 2026-08-13
Scope: local regression status and evidence maintenance only

## Observed failure

A combined `apply_patch` update paraphrased one evidence anchor as `Feed return state`; the actual file contained `Feed dock state`. The patch was rejected before any file changed.

## Prevention

Read each target tail first, update registry statuses in a bounded exact patch, and append resolution sections using exact local anchors. No build, upload, install, device mutation or external write was attempted.
