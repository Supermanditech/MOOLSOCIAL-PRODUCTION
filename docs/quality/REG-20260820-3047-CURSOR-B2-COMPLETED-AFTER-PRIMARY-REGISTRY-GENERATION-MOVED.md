# REG-20260820-3047 Cursor B2 completed after primary registry generation moved

## Observed failure

Cursor completed B2 reconstruction and stopped before qualification/staging as
required, but primary mandatory incident registrations moved the registry after
Cursor's B2 pin. Its 8,352-record manifest is retained as reconstruction
evidence but is stale for qualification, staging, commit or tag.

## Root cause

Independent primary readback work produced mandatory incidents while external
B2 reconstruction remained in flight. Registry movement invalidated Cursor's
bound generation before its bounded completion report arrived.

## Impact

- the existing B1 worktree and B2 reconstructed owner set are preserved;
- qualification, staging, commit and tag did not start;
- original checkout, main, push, build, Play, OPPO, provider and external state
  were unchanged by Cursor;
- the stale manifest is not accepted as a qualification pin.

## Prevention and authorized continuation

Freeze primary registry writers during the incremental B2 refresh and later B3
qualification window. Preserve reconstructed owners; copy only owners changed
by the new registry generation, update the worktree state binding, regenerate
the complete manifest, replay mandatory gates and stop before qualification.
