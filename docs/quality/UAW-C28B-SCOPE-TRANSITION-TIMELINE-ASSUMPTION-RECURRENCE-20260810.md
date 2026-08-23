# C28B scope transition timeline assumption recurrence

- Date: 2026-08-10
- Phase: successor ticket selection
- Mutation before failure: none; apply_patch rejected the whole scope hunk
- Device effect: none; installed r60.26 remained unchanged
- Rejection: the C28B transition expected `timelineImpactDays` to be 2, while
  exact C28A state still held 1.
- Root cause: too many assessment owners were coupled into one transition hunk
  and one scalar was assumed instead of read back, recurring the REG931/REG932
  scope-owner pattern.
- Prevention: read back the complete selected assessment, then patch one
  bounded object group at a time with exact current values and validate JSON
  after every group.
