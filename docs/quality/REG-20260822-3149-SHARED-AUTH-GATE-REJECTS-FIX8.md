# REG-20260822-3149 — shared-auth gate rejects FIX8

Date: 22 August 2026

State: registered; cycle 1 receives zero qualification credit

The first frozen FIX8 source cycle passed full analyzer, 255 affected tests and
approved UI locks, then the inherited shared public-authentication gate rejected
the selected FIX8 ticket before behavior checks. No later gate or device action
ran. Registry movement supersedes the preceding cycle results.

Root cause: the shared gate's authorized C34P ticket set predates the exact FIX8
repair descendant.

Prevention: add only the manifest-bound FIX8 source-repair identity to the
shared gate while preserving the parent/FIX5 branches, runtime-source checks,
secret/private prohibitions and build/Play/OPPO holds. Restart both complete
source cycles after gate repair and generation replay.
