# UAW C31E first photo-journey test failures lacked state projection

Date: 2026-08-15
Ticket: `UAW-C31E-PERSONAL-MVP-CHAT-PHOTO-ATTACHMENT-CONTINUITY`

## Rejected attempt

The first run of `chat_photo_attachment_test.dart` completed three tests and
failed two. The gateway prepare/upload/finalize contract, finalize retry and
interrupted staging passed. The session's third exact-caption send returned
false after a deliberately rejected changed-caption attempt, and the widget
did not show `Photo delivered.` after its send tap.

The run is zero qualification evidence. Its assertions did not emit the exact
busy, thread error/notice, pending photo, gateway request count or widget
hit-test/action state required to distinguish a client-state defect from a test
harness interaction failure.

## Required next diagnostic

Before correcting product source, the bounded tests must project those values
at the failing boundary. The widget must bring the send control into view and
await its action boundary. The two symptoms are not assigned a shared cause
without evidence. No build, deployment, Play action or OPPO mutation occurred.

## Resolution

The registered diagnostic retry showed `busy=false`, retained pending state,
two gateway requests and the generic post-gateway failure. Source inspection
then proved the session had retained a fixed-length gateway message list and
threw while appending the authoritative delivered photo. The same ownership
mismatch exists in production because `AuthenticatedChatGateway.listMessages`
returns `toList(growable: false)`. REG-2240 owns the permanent correction.
