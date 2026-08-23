# REG3098 — data-extraction rule owner policy context mismatch

- Date: 2026-08-21
- Status: registered before retry

The attempt to claim the new Android data-extraction rule used a nearby styles
owner that is not present in the current primary claim, so `apply_patch`
rejected the hunk. No policy, resource, build or device state changed.

Prevention: inspect the exact Android owner range and insert the new resource
beside the verified manifest owner rather than inferring adjacent owners.
