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

- Completed a full-depth professional revision. Family identity and the active
  subaction now remain visible through the inbox context banner, new-chat
  chooser, participant thread header, context card, welcome state, thread menu,
  conversation search, inline sharing and conversation information.
- MoolSocial navy remains the common interaction color. Food orange, Travel
  slate, Care teal and Work green are limited to identity, context and status
  accents so every family remains recognizably MoolSocial.
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
- Sharing actions are context-aware. Product and order references remain
  available for food/medicine purchase contexts, while irrelevant commerce
  actions are removed from travel, doctor, salon and work trays. Workspace also
  omits location sharing. The production action handler remains authoritative.
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
  pass, `99/99` executed tests; one screenshot generator skipped by default.
- Existing Social action/accessibility, creator ergonomics, footer compaction
  and subaction conformance: pass, `10/10` tests.
- Explicit contextual candidate-capture run: pass, `1/1` test.
- All `20` contextual candidate screenshots passed manual visual inspection at
  `390 x 844`. The complete set covers Inbox, New conversation, Conversation,
  Inline sharing and Conversation information for every service family.

| State | SHA-256 |
| --- | --- |
| `food-order-food-inbox` | `13D9B41286068C1F63067F3B71BAB51586DBEBDB9273601E78AAFCCE6F07431A` |
| `food-order-food-new-conversation` | `6BD4088BE6BF939EC689B485471D49EA9968B67B77366994BF240BA7C1B79786` |
| `food-order-food-conversation` | `32B7FA03632F377784BA46E27077C333563A9BA15535D8FF8184DB8F41E52599` |
| `food-order-food-attachments` | `F91744D8B59F3F6349857ACEF861E584D0B6EB1302E21E762BEBB0D586CA893F` |
| `food-order-food-conversation-info` | `299E8434523B5E9BC98C67666E8BDBB52FF980EAB8A7D3845F565C1E506B503D` |
| `travel-cab-inbox` | `BA02A25D54E2E16BF22F80056BEAD09ED872E3DD3E3D248AE26294EC84C391F9` |
| `travel-cab-new-conversation` | `8D101D0A19178FF30E998D3656CD6E1990ED62FB9F57B4E26B650531E056AA6F` |
| `travel-cab-conversation` | `0410308549DED4B9C6AD9DAF9A6FA89AB5A884C7BAE7737EC5E0914A5242C991` |
| `travel-cab-attachments` | `7C4B23AD9E59761862A4A09D4171F7D0507A24D2C77065D65F85475C2A8AB8A8` |
| `travel-cab-conversation-info` | `0D15CB0D680C3EC625CF1153FC06C036A8FDADD37767DE004836FD08EEB3E88C` |
| `care-doctor-inbox` | `121D8C22134AF87AF0CB20FFA5755C54191BEF6CD0D6AF9F14ED43C50CA045EF` |
| `care-doctor-new-conversation` | `7CD62FBAAF79E0AB7152FE683669977399A0FDBF453B9DFE698126B7FD4F7767` |
| `care-doctor-conversation` | `A68EBCC07121BA7C0242A61E7B86FEF5825904E12D5455E722B53A53AE7AE63E` |
| `care-doctor-attachments` | `3AB34BE567964F2C5F7D116EECCA8C3F0DD9CB544901B490334D58E777BF2F30` |
| `care-doctor-conversation-info` | `B3B0087E6C84EF81A9C969C692E0C82CA6C48C4BBA760D2669E60BCA912B8EC0` |
| `work-earn-today-inbox` | `D9CF98A5306FFBDBA621200C4A1E3B90F81E169CEF6EE1C9B826C6CC8F37B6BC` |
| `work-earn-today-new-conversation` | `CC1AEBB691ADABA67073528912A7C16F86872002A7D1F033662DD5A62320E39F` |
| `work-earn-today-conversation` | `9751D50DCE586BD4390D9406BB193EE1A7DED892662206A7099AEFDD5B5E99A3` |
| `work-earn-today-attachments` | `401A86012973EFB527CCE4442DD7F11C57C7CCDCCAB9A18F14671DA264E5A112` |
| `work-earn-today-conversation-info` | `FF2A1EBFB656164364B7093817B6B0FAE580B10FF3F5DD3A28AC10E231235F9A` |

## Approval state

The contextual Chat laptop candidates are ready for founder UI/UX review.
Integration, new APK creation, installation and OPPO approval remain later
explicit steps.
