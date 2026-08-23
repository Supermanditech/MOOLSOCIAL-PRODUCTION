# UAW C31E Chat photo attachment continuity preselection

Date: 2026-08-15
Ticket: `UAW-C31E-PERSONAL-MVP-CHAT-PHOTO-ATTACHMENT-CONTINUITY`

## Classification and customer outcome

This is `mvp_required`. A signed-in member must be able to send one private
photo in an existing conversation and recover safely from cancellation,
upload failure and retry. Today the production owners support authoritative
text, reply, reaction, unread/read and forwarding, while attachment labels are
non-interactive and camera/gallery controls are deliberately absent.

## Reuse and duplicate search

The ticket reuses the two existing Chat routes, `ChatSession`, the authenticated
`moolSocialChat` endpoint, current App Check/Auth verification, the existing
thread message subcollection, existing private Firebase Storage bucket and the
already installed `image_picker` package. It adds no route, route-level screen,
top-level Firestore collection, function service or duplicate state owner.

The public Social storage adapter cannot safely be reused as-is because it
creates persistent public download tokens. Private Chat needs one narrow
Storage adapter under the existing Chat service to issue time-limited V4 write
and read URLs, bind an upload to one participant and thread, enforce a
create-only generation precondition and validate the stored object before the
message transaction. This is the only new necessary backend source owner.

## Smallest complete implementation

Only JPEG, PNG and WebP photos up to four MiB are in scope. The client prepares
an upload using authenticated limited-use App Check, uploads once using the
exact signed headers, then finalizes one idempotent photo message. Finalization
checks membership, owner/thread metadata, byte length, content type and file
signature. Read access is signed only after membership is proven and expires
quickly. Internal object paths and signing material never enter the public
message fields; the short-lived direct Storage URL necessarily contains only a
random opaque UUID object locator with no user, thread or filename data.

Documents, video, voice, polls, groups, contact discovery, calls, presence,
notifications, attachment forwarding and external share remain separately
traceable successors. No live Dev write, deployment, IAM/rules/CORS/lifecycle
mutation, build, Play or OPPO action is part of C31E source work.

## Robustness and test plan

Tests cover non-member, wrong-thread, spoofed type, corrupt signature,
oversize, replaced object, idempotent retry and conflict; private response
redaction and read URL expiry; picker cancellation and interrupted recovery;
offline/upload/finalize retry; stale route completion; draft retention; inline
loading/error accessibility; and cumulative C30T/C31A/C31B/C31C regressions.
Two identical source cycles are required before C31E may be called
source-qualified.

Google Cloud documentation confirms that V4 signed URLs provide time-limited
read or write access, generation preconditions prevent unintended overwrite,
and bucket lifecycle policy is the separate control for stale objects. Those
runtime permissions and bucket changes remain approval-gated and are not
performed by this ticket.
