# C30T full Flutter inventory classification

## Result

The complete Flutter inventory finished with:

- 699 passing tests
- 31 skipped tests
- 193 failing tests

The failure set is dominated by historical Shop, Care, Work, motion, and golden-review expectations outside the founder-authorized C30T Social/YouTube/Chat implementation scope. Representative failures include stale Buy medicine golden pixel comparisons, older contextual-header review goldens, and vertical-slice tests that implicitly relied on the historical in-memory Chat fixture.

## Classification

- C30T scope-critical Social, YouTube, Feed, Create, Chat, auth, retry, compact-device, and shared-navigation tests are separate required gates and must pass.
- Backend functions, security boundaries, and Chat service tests are separate required gates and must pass.
- Broad Shop/Care/Travel/Work/Food historical design and golden tests are inventory evidence only for C30T. Their deep UI, UX, backend, database, and journey redesign remains frozen until after the YouTube reviewer package, as directed by the founder.

## Small compatibility correction

`MoolSocialApp` keeps its historical injected/default fixture behavior for test harnesses. The actual product entrypoint now explicitly supplies and owns `ChatSession.production()`. This preserves a real release Chat path without making unrelated historical tests silently depend on a live Dev endpoint.

## Permanent rule

Do not update unrelated goldens, restore prototype-only release features, or redesign frozen domains to force a global pass under C30T. Track those failures for their later domain-specific review and require the exact C30T release partitions to pass before a build.
