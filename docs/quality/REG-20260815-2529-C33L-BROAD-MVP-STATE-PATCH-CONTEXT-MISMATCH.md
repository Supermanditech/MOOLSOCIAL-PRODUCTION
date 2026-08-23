# REG-20260815-2529 C33L broad MVP-state patch context mismatch

- Date: 2026-08-15
- Failure: one expected block in a multi-hunk C33L MVP-state patch did not
  match the exact dirty-tree text, so `apply_patch` rejected the full patch.
- Impact: the rejected patch wrote no hunk and caused no product, release,
  Firebase, Play or device change.
- Prevention: re-read each narrow current block and apply small independently
  verified hunks instead of retrying broad projected context.
- Resolution: narrow verified hunks applied, the resulting JSON parsed, and
  the delivery-discipline plus authorized MVP scope gates passed for C33L.
