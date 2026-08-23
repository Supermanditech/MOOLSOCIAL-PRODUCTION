# UAW C31E personal MVP Chat photo attachment continuity qualification

Date: 2026-08-15
Ticket: `UAW-C31E-PERSONAL-MVP-CHAT-PHOTO-ATTACHMENT-CONTINUITY`
Classification: `mvp_required`

## Outcome

The scoped source repair is complete and qualified. A signed-in MoolSocial
member can stage one JPEG, PNG or WebP photo up to 4 MiB from gallery or camera,
confirm it in the existing conversation, retain the exact caption/reply/thread
and idempotency state across recoverable upload or finalize failures, and append
only the authoritative delivered photo message. Interrupted selection is staged
without auto-send. Late completion remains bound to its originating thread.

Private Storage source uses a random UUID-only object locator, five-minute V4
signed create-only upload, exact signed size/type/binding headers, stored
metadata and file-signature validation, one-time attachment receipt, and a
five-minute generation-bound participant-gated read URL. Raw object path,
generation and binding metadata are not separate public response fields. The
short-lived URL necessarily contains its opaque UUID locator.

Photo messages retain reply, reaction, unread/read and refresh behavior. They
cannot be forwarded. Documents, video, voice notes, polls, groups, contacts,
calls, notifications, external share, new routes, new screens, a new function
service and a new top-level Firestore collection remain excluded.

## Escaped production Chat defect repaired

C31E tests exposed an older shared defect: `ChatSession` adopted the fixed-
length list returned by `AuthenticatedChatGateway.listMessages` as mutable
session state. A subsequent production text or photo append could throw after
messages loaded. The session now takes a defensive growable copy at that
ownership boundary, and the fixed-length regression remains retained.

## Exact source seal

- Manifest: `artifacts/quality/uaw-c31e-personal-mvp-chat-photo-attachment-continuity-20260815-01/source-manifest-c31e.txt`
- Files: 49
- Fingerprint: `401C5C59F9522C173379AD5D17C140E1CFB76C362910674E683C5B57E57C4DF5`
- Cycle evidence: `cycle-01-summary.json`, `cycle-02-summary.json`

Both cycles independently passed:

- regression memory: 2,213 entries; 1,297 implementation-applicable;
- backend TypeScript typecheck;
- 24/24 focused backend Chat tests;
- 47/47 Flutter Chat tests across six files, zero skips/failures;
- whole-mobile Flutter analyzer with no issues;
- C31E static contract on PowerShell 7 and Windows PowerShell;
- MVP scope, robust-delivery discipline and approved-UI locks.

## Held live prerequisites

Source qualification is not live readiness. No backend, Storage, IAM, CORS,
lifecycle, provider, Hosting or Firebase deployment occurred. No AAB/APK was
built; no Play action or OPPO mutation/test occurred; no credentials or secret
values were accessed.

Live acceptance remains blocked until separately authorized work proves:

1. the runtime service account can perform V4 signing and has only the required
   private object permissions;
2. exact bucket CORS, if required by the native signed upload path;
3. an orphan-object lifecycle policy for staged uploads never finalized;
4. a fresh Dev-only function deployment and two real participant accounts;
5. gallery, camera, cancellation, offline retry, participant denial, refresh,
   relaunch and route-switch behavior on a separately approved Play candidate.

The failed r60.48 release remains failed with build/upload/install counts
`1/1/1`. This ticket creates no successor AAB authority and makes no production-
grade or real-device-success claim.
