# UAW-CURSOR-CONTEXTUAL-CHAT-UI-20260824

Founder date: 24 August 2026 IST
Lane: `cursor_ui`
Branch: `work/cursor-ui/shop-chat-ui-20260824`
Accepted consolidated product baseline:
`ee5aa07ac8ec29e102832e84991ab7ec421da808`
Implementation parent for this continuation:
`5cddb31036cfb3346aaee61cb0bcdd4dfdf12221`

## Customer outcome

The approved standalone Shop Chat interaction is now shared by Food, Travel,
Care and Work while each family keeps its own labels, filters, participants,
context cards, quick replies and exact return destination. Chat opens from the
family header or global Chat action, replaces the family surface completely,
and never competes with the shared destination or subaction rails.

## Context coverage

| Family | Subactions connected to Chat |
| --- | --- |
| Food | Order Food, Book Table |
| Travel | Bike, Auto, Cab, Bus |
| Care | Doctor, Medicine, Salon |
| Work | Earn Today, Workspace |

Each entry point opens the matching filter and preserves its originating
subaction. The conversation context card returns directly to that subaction.
Changing family or subaction closes Chat through the existing navigation path.
System Back unwinds information, thread, new-conversation and inbox depth before
returning to the originating family surface.

## Runtime implementation

- Generalized the production Shop Chat presentation layer so one tested native
  runtime owns inbox, search, filters, new conversation, conversation, message
  composition, inline attachments, emoji, calls, thread utilities, business
  information and message actions.
- Added family-specific presentations and truthful starter entries. Default
  entries identify possible conversation endpoints only; every default message
  history remains empty until an authoritative Chat source supplies it.
- The selected family and subaction determine the title, origin label, search
  copy, active filter, security guidance, participant role, context card and
  quick replies.
- The entire shared main-action and subaction rail is absent from the widget
  tree while contextual Chat is active. The Chat composer exclusively owns the
  bottom safe area.
- The familiar composer keeps emoji, a wide editable message field, inline file
  sharing and camera inside the message capsule, with mic/send outside. Calls,
  attachments and sends dispatch typed runtime intents and never claim success
  when no provider accepts them.
- Directional navigation and filter motion reuse the reviewed Shop Chat motion
  contract and respect reduced-motion settings.
- Interactive controls retain 44 logical-pixel minimum targets. Focused coverage
  proves the surface at 320 logical pixels and 140 percent text scaling.
- Existing Social feed, YouTube, global Chat routing and the Shop Chat customer
  journey remain unchanged.

## Provisioning and action seams

`MoolContextualChatProvisioningSource` is the frontend connection point for an
authoritative service to publish the threads visible to a signed-in user for a
family. `MoolContextualChatSourceAdapter` feeds those records into the shared
Chat runtime. `BuyV2ShopChatActionHandler` remains the typed connection point
for text, document, image, video, camera, voice, call and conversation actions.

The default implementation supplies only safe conversation starters for design
continuity. It does not create messages, delivery/read receipts, timestamps,
uploads, assigned participants, calls or fake runtime success.

## Backend connection points for later tickets

The runtime UI and navigation are ready. These production services remain
intentionally deferred:

- Food: authorized restaurant, order and reservation participants; live order,
  menu, table, slot and fulfilment context.
- Travel: assigned driver/operator and booking authorization; vehicle, route,
  pickup, trip, fare and live-status context.
- Care: authorized provider, pharmacy and salon participants; appointment and
  order visibility, consent, sensitive-data controls and emergency guardrails.
- Work: verified employer/opportunity actors, workspace membership, role-based
  document access and work-state context.
- Shared Chat transport: paginated message streams, idempotent send, delivery
  and read state, retry/offline reconciliation, media upload/storage/scanning,
  RTC signalling, recording, push, presence, moderation, retention, encryption,
  block/report and audit controls.

No backend, provider, global Chat, authentication, Social behavior, Android/iOS
platform, Firebase, signing, configuration, build, deployment, policy or
registry owner was modified. No APK was built or installed for this laptop
screenshot-review stage.

## Focused verification

- Targeted Flutter analysis across all six modified/new source and test owners:
  pass, no issues.
- Combined Buy screen, Buy navigation motion, Shop Chat and contextual Chat:
  pass, `98/98` executed tests; one screenshot generator skipped by default.
- Existing Social action/accessibility, creator ergonomics, footer compaction
  and subaction conformance: pass, `10/10` tests.
- Explicit contextual candidate-capture run: pass, `1/1` test.
- All candidate screenshots passed manual visual inspection at `390 x 844`.

| State | SHA-256 |
| --- | --- |
| `food-order-food-inbox` | `89C882A2D2F8596748BE2F9CBD0053E28BC2CB88A2AA26B568F8107A6AAED860` |
| `food-order-food-conversation` | `77BEDBDF214AE5A2310ACBDF67235D629EE695F644E808355A6C7DFD4055AEAE` |
| `travel-cab-inbox` | `2ECCDE7BFF866A903677C11DAC6CFD97E9914765D72DE34FD9F6AA3507F94282` |
| `travel-cab-conversation` | `B1FB455A6CAFEF1FA84AC89496AE6BF3F09C424AB2338A7E7D2C940DA14F6875` |
| `care-doctor-inbox` | `7EC931B109CB7CB1A0E366427F52FA2381CEED4C6CE2E16A233590108143DF16` |
| `care-doctor-conversation` | `082000D22BEF683338EA1ABBC96F051DDB85A4B261EFDA0BC3FCCA145D207DC6` |
| `work-earn-today-inbox` | `986CBFA4E2BCEB10ABD0679747DEAA5711335805B81874D7A719D0D026DF22F1` |
| `work-earn-today-conversation` | `D54EB9C49950478A5078595B79B92F8EA82F854CAD21EEC299F8E9E334B9CEFE` |

## Approval state

The contextual Chat laptop candidates are ready for founder UI/UX review.
Integration, new APK creation, installation and OPPO approval remain later
explicit steps.
