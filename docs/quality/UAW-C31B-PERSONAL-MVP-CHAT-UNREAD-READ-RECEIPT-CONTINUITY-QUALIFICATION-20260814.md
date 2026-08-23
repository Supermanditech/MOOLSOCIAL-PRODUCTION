# UAW C31B Chat unread and read-receipt continuity qualification

Date: 2026-08-14
Ticket: `UAW-C31B-PERSONAL-MVP-CHAT-UNREAD-READ-RECEIPT-CONTINUITY`

## Outcome

The existing authenticated Chat owner now persists per-participant unread counts, acknowledges a successfully loaded thread through an authenticated idempotent mutation, and derives sender read status as an aggregate count and boolean. Reader IDs and private read timestamps remain server-side and are not returned in the public message contract.

Legacy thread/message records without the additive maps decode as zero unread and delivered. A stale older thread load cannot acknowledge the newer route, and read messages retain the C31A reply/reaction actions.

No new route, route-level screen, backend service, endpoint family or top-level Firestore collection was added.

## Two identical cycles

Both cycles used the same 29-owner qualification fingerprint:

`17E698C43C0EE19BE94FBDDEA795F31F6628BFEF0C80C81A8B092D8FD09CBB10`

Each cycle passed:

- permanent regression-memory gate: 2,103 entries; 1,199 implementation-applicable;
- MVP delivery-discipline and exact C31B scope gates;
- C31A predecessor and C31B current static gates in PowerShell 7 and Windows PowerShell;
- backend TypeScript typecheck;
- 12 backend service/Firestore repository tests, 0 failures;
- 36 cumulative Flutter Chat, navigation, exact-return and golden tests, 0 failures;
- whole-mobile Flutter analyzer with no issues.

The durable 27-file historical implementation manifest fingerprint is:

`7EA3C39F7A4A5D372DE675DA7E63472A5299AFB05025A416F805EBC932556015`

## Reference and release truth

There is still no approved Chat screenshot in `approved-references/manifest.json`. The new read-state golden is regression evidence only. Supplied messaging screenshots remain behavioral references, and no third-party name, logo, trade dress, proprietary icon or exact composition was copied.

No live Dev Chat read acknowledgement or other data write occurred. No deployment, build, Play, OPPO, secret-access or communication action occurred. r60.47 remains failed at cold start; no successor AAB is authorized.
