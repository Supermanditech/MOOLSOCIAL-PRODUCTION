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

---

# Final Cursor Chat integration handoff — 25 August 2026 IST

This section supersedes the earlier implementation-parent, verification and
approval-state text above. The earlier visual evidence and screenshot hashes
remain preserved as historical evidence.

## Authoritative implementation state

- Lane: `cursor_ui`
- Work ID: `shop-chat-ui-20260824`
- Ticket: `UAW-CURSOR-CONTEXTUAL-CHAT-UI-20260824`
- Task: `/root/cursor_shop_chat_ui_20260824`
- Worktree:
  `C:\GUARANTEED OUTCOME\MOOLSOCIAL-WORKTREE-CURSOR-buy-screen-subactions-ui-20260823`
- Branch: `work/cursor-ui/shop-chat-ui-20260824`
- Continuation baseline: `3470d2f0fc9111590afe8d8b7adb84f312c4ceee`
- Final product implementation commit:
  `b14a068cdabb982aab8751f507e1c33c6ae40c02`
- Linear implementation commits after continuation baseline: `37`
- Merge commits in the implementation range: `0`
- Product worktree status at handoff: clean, zero status records
- Cursor owner claim: exactly `108` files
- APK, merge, integration or release action performed by Cursor: none

The commit which adds this documentation is intentionally not
self-referential. Integration must verify that the current feature-branch HEAD
is a documentation-only direct child of product commit `b14a068...`, and that
the child changes only this handoff file. The product-code review boundary
remains `3470d2f...b14a068`.

At the time this handoff was prepared, the remote ref
`origin/work/cursor-ui/shop-chat-ui-20260824` was absent. Integration is
fail-closed until the primary pushes the exact branch without rewriting
history and proves remote readback equals the final documentation handoff HEAD.

## Aggregate implementation boundary

The product implementation changes exactly these nine files relative to
`3470d2f...`. Any additional Cursor-side product path must fail integration
review.

| Code | File | SHA-256 at `b14a068...` |
| --- | --- | --- |
| `BS` | `apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart` | `8840BF8542D3B5B5EBEE5F250400A33AD36AA509BA4D807742C1F2F7901B5BFB` |
| `BC` | `apps/mobile/lib/ui_v2/buy/buy_v2_shop_chat.dart` | `2ADDE1C2526319EFDAC989281DD75175CDFE1245A7488BDFD7AE63972A74A64D` |
| `BV` | `apps/mobile/lib/ui_v2/buy/buy_v2_views.dart` | `2DDF680A9FAA5F711EA0B24069D36A2AA2BB169F638C65D50C60FC849A8533BD` |
| `SC` | `apps/mobile/lib/ui_v2/social/social_v2_consumer.dart` | `8ADC82D06CBECF048E2C212D14F8CD9FEC94CD6853FD799678916217F4A070C6` |
| `CC` | `apps/mobile/lib/ui_v2/universal/mool_contextual_chat_v2.dart` | `44805FCE3C82829652E6E4BE75F02BE8580DE8B890C90FC3CB89BFBBB74B0AA8` |
| `BST` | `apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart` | `63DBD857A0A87E4CA24A1E16DE36A96556EC2D818CF1CC950ABF50E0BA4A6F7E` |
| `BCT` | `apps/mobile/test/ui_v2/buy/buy_v2_shop_chat_test.dart` | `EBF937EEA5DB62E52D87DECCD55C0D391F0C894FEC2FB731DAAE6EAB85AE085F` |
| `DKT` | `apps/mobile/test/ui_v2/buy/uaw_personal_mvp_buy_local_tabs_global_dock_c10c_test.dart` | `4387B07F0FE1E1005D4E7762B35B2E6B41CA5A6E88F3145E20D2F0C32089602C` |
| `CCT` | `apps/mobile/test/ui_v2/social/social_v2_contextual_chat_test.dart` | `EBC60C02CDBB975C94BD183EDFD0A7892C2757406C15855E853AD1671DA1FE33` |

Aggregate implementation diff: `5,285 insertions`, `764 deletions`.

## Complete ordered implementation commit chain

The commits are intentionally sequential. Do not cherry-pick, squash, rebase,
reorder or omit individual commits. Merge the approved feature branch once
with the repository-required no-fast-forward strategy.

| Ticket | Commit | Outcome | Files |
| --- | --- | --- | --- |
| 1 | `0491c02796a503ab082256e15850fcc0bc93851b` | Restore exact contextual Chat return routes. | `SC`, `CCT` |
| 2 | `77f531c0814f17fd7444fca493a6288fcc0c36ac` | Remove unsupported security and encryption claims. | `BC`, `BV`, `CC`, `BST`, `BCT`, `CCT` |
| 3 | `867743ff52d9867036152c232783638bc0b475ea` | Make conversation-picker language truthful. | `BC`, `CC`, `BCT`, `CCT` |
| 4 | `1a141995ebe834dfb667f7fae5a0f696b3cab471` | Keep Care safety guidance visible in Chat. | `BC`, `CCT` |
| 5 | `47e141e130b0d8b8784a9418fc235e581d2bec8f` | Add Android Back and in-app Forward history. | `BC`, `BCT`, `CCT` |
| 6 | `9651aefea71cb76f79a16ff54065e8f960b1a5bf` | Retain filter, query, draft, reply and search work in progress. | `BS`, `BC`, `SC`, `BCT`, `CCT` |
| 7 | `e5d3d4d8c9a2c30804e613329c2cb7504af6b014` | Expose direct message Forward actions. | `BC`, `BCT` |
| 8 | `1c05980bec200222b7d13261432f37db88b93178` | Hide controls unsupported by thread capabilities. | `BC`, `BCT` |
| 9 | `8de2f9592a4d1983dbcb77019cbd6922dd6dfaf5` | Make action recovery immediately retryable. | `BC`, `BCT` |
| 10 | `4ebd7829b382e7330807d41f2583059aa025b5a3` | Make composer keyboard and compact layout safe. | `BC`, `BCT` |
| 11 | `9d12a147c6e54137a307e46f20327b543968493d` | Clarify accessible message content, status and actions. | `BC`, `BCT` |
| 12 | `b7b473dc44302541b37b5bdd131020dda1125839` | Prevent duplicate Chat Info actions. | `BC`, `BCT` |
| 13 | `33d52bbdd2ff3d84b32b7fd0a4f74670cf41da83` | Make empty states actionable. | `BC`, `BCT` |
| 14 | `5f22630aa17b9f7cb8c9de4ba5f75cbea4de4e38` | Prevent duplicate conversation actions. | `BC`, `BCT` |
| 15 | `ed6f0a1cfe2efbfa141f0cbd6f6b87e6bda299b6` | Restore nested utility Back and Forward history. | `BC`, `BCT` |
| 16 | `e30cf89753a7dcef83fcb3a2bc339ffeb2942878` | Expose every same-type conversation target. | `BC`, `BCT` |
| 17 | `3d3c3a72f68d4dc8d223de99062b4ace6b460485` | Dismiss composer keyboard before leaving the thread. | `BC`, `BCT` |
| 18 | `41b6167e598ce734823d5d56d6b4ad0c408ffb13` | Announce conversation action progress accessibly. | `BC`, `BCT` |
| 19 | `7a2f776eeb1fff037ea5a300fcff278141b23ca3` | Retain conversation-picker scroll position. | `BC`, `BCT` |
| 20 | `16880d4af8f456dd050e3e9066a6793c6178c4ca` | Retain inbox scroll position. | `BC`, `BCT` |
| 21 | `f8fccd046fa468148adf57fdd450fb97efec7e97` | Retain timeline scroll position. | `BC`, `BCT` |
| 22 | `0eb3b6bf0f58ed88a20b06520e873bafa259c820` | Clarify menu semantics and enabled state. | `BC`, `BCT` |
| 23 | `0e08bdefa675785dad6d6d0ececf526f744e5cad` | Clarify Chat Info call semantics. | `BC`, `BCT` |
| 24 | `435a9547914a624bc7550eb0a46e4375c00d96ab` | Align visible Close, cancel and toggle history with Android Back. | `BC`, `BCT` |
| 25 | `5168d640727f10face23f1af17aa56318f198496` | Return context cards to the selected subaction. | `SC`, `CCT` |
| 26 | `e7cbc4f2425c904139585ef615952bf232b4d17d` | Open isolated Care Chat from Medicine. | `BS`, `BCT` |
| 27 | `27aa96d9de03be53a974b72b024e91978222d530` | Dismiss inbox-search keyboard before leaving Chat. | `BC`, `BCT` |
| 28 | `749676241432eb63f329f7ec85996c4541824aa7` | Announce exact contextual search identity. | `BC`, `CCT` |
| 29 | `2c6e939aef7038c847631bc02b7ccfef725f42e0` | Identify message sender, Forward ownership and reply ownership. | `BC`, `BCT` |
| 30 | `538c7630904e2aefd1c03d5226531972db3a33ea` | Preserve draft, category and exact production-Chat return. | `BS`, `BC`, `SC`, `BCT`, `CCT` |
| 30A | `599e129c004943d763392ee318537ab838f56fd9` | Align global launcher contract with inline-first Chat. | `DKT` |
| 31 | `6676ecb2dcafb0741a8760f06cdb4414f1f78966` | Derive handoff return from the selected thread context. | `BS`, `SC`, `BCT`, `CCT` |
| 32 | `0a95a6341902a560a679d728b87ff402b3253ef5` | Add live provisioning and removed-thread recovery. | `BC`, `CC`, `BCT`, `CCT` |
| 33 | `fe43245fbeedd3dff1da2ab9ba6a13dc7b5159ba` | Scope reply IDs to message-producing actions and consume once. | `BC`, `BCT` |
| 34 | `ae35326c33c7ee5ec449bdfc1f622c3d83fbf551` | Clear contextual Chat state at authentication identity boundaries. | `SC`, `CCT` |
| 35 | `0cdf6ac67a7dc836f0a9d808e23727987be9caf7` | Reconcile live thread and message changes into history. | `BC`, `BCT` |
| 36 | `b14a068cdabb982aab8751f507e1c33c6ae40c02` | Expose optional loading, failure and retry provisioning. | `BC`, `CC`, `BCT`, `CCT` |

## Final standalone verification at `b14a068...`

- Shop Chat suite: pass, `37/37`.
- Contextual Chat suite: pass, `15/15`; one candidate-capture test is
  intentionally skipped by default.
- Buy global/local launcher suite: pass, `2/2`.
- Buy Assist truthful Chat-copy test: pass, `1/1`.
- Social author guest authentication handoff: pass, `1/1`.
- Production Chat draft consumption: pass, `1/1`.
- Global Chat exact-return suite: pass, `3/3`.
- Total active targeted tests at final product HEAD: `60` passed.
- Flutter analysis over all six active implementation/test owners: pass, no
  issues.
- Approved Screens 01–03 lock check: pass.
- Regression-memory implementation gate: pass, `3698` entries and `2171`
  applicable entries.
- Cursor coordination gate: pass, exactly `108` owners.
- Compact rendering: exercised at `320 x 568` with `140%` text scaling.
- Standard rendering: exercised at `390 x 844`.
- Worktree after tests: clean.
- Remaining Flutter/Dart test processes: none.

No combined UI/backend regression or physical OPPO validation has run because
integration has not occurred. Standalone evidence cannot guarantee zero merge
side effects; the fail-closed integration replay below is mandatory.

## Backend contracts Codex must preserve

### Provisioning

Codex should provide production implementations of:

- `BuyV2ShopChatProvisioningSource`
- `MoolContextualChatProvisioningSource`

Production sources should implement `Listenable` so the frontend receives live
thread and message updates without remounting.

Asynchronous sources should also implement `BuyV2ShopChatLoadSource`:

- `loadState`: `ready`, `loading` or `failed`
- `loadErrorMessage`: customer-safe language only
- `retryLoading()`

Required invariants:

- Thread IDs are globally stable.
- Message IDs remain stable across refreshes.
- `resolvedFilterId` matches a declared presentation filter.
- Participant identity and `fromCurrentUser` are authoritative.
- Capabilities reflect real runtime support before the first tap.
- Removed threads are omitted from the next live snapshot.
- Account-owned source data is cleared on sign-out or account replacement.
- Diagnostics, raw provider failures, HTTP messages and internal codes never
  appear as customer copy.

### Action seam

Codex should connect:

- `onShopChatAction`
- `onContextualChatAction`

`BuyV2ShopChatAction` supplies:

- `kind`
- `threadId`
- `text`
- `messageId`
- `replyToMessageId`

Message-producing actions may carry `replyToMessageId`: text send, camera,
media, document, voice message and product/order/location/contact sharing.

Voice/video call, Forward, reaction, notification, safety and attachment-open
actions must not receive a reply ID.

Return dispositions:

- `accepted`: the real runtime operation completed successfully.
- `handedOff`: the runtime intentionally navigated to production Chat.
- `unavailable`: the operation failed and includes truthful customer-safe
  recovery copy.

Frontend concurrency guards do not replace backend idempotency. Codex must not
return `accepted` before the real operation completes.

### Production Chat fallback

When no inline handler exists, the frontend emits these route parameters:

- `type`
- `draft`
- `return`

It intentionally does not emit `start`, because Cursor has no authoritative
target identity. Codex must supply a verified target user/thread mapping before
using `start=<user-id>` or `/app/chat/thread/<real-thread-id>`. Presentation-only
thread IDs must never be treated as backend identities.

### Capability truth

If a backend feature is absent, disable the matching capability before render.
Do not leave a visible call, media, share, notification or safety control that
only fails after the first tap.

## Known unresolved cross-owner items

1. Authoritative contextual target user and thread IDs remain backend-owned.
2. Full action-provider and API wiring remains Codex-owned.
3. Process-death persistence for drafts requires an agreed persistent runtime
   store.
4. Social Message Author carries the author ID but drops the originating post
   ID from its return route. Its locking contract test is outside Cursor's
   exact owner set.
5. Physical-device IME, system gesture, process-death and OPPO validation remain
   integration/APK-stage work.
6. The remote Cursor feature ref is absent and must be created and read back
   before integration.

## Fail-closed integration procedure

### 1. Approve and push the exact feature branch

The primary must push the current feature HEAD without force, squash, rebase or
history rewrite. Then run:

```powershell
git fetch --prune origin
git rev-parse origin/work/cursor-ui/shop-chat-ui-20260824
```

The result must equal the final documentation handoff commit supplied alongside
this file. That commit must be a direct child of `b14a068...` and must change
only this Markdown file.

### 2. Use only the authorized integration worktree

Do not integrate in the production checkout, Cursor worktree, Codex backend or
authentication worktree, or `main`. The founder-authorized integration worktree
and branch must be clean before any merge action.

### 3. Verify product ancestry and boundary

```powershell
git rev-list --count 3470d2f0fc9111590afe8d8b7adb84f312c4ceee..b14a068cdabb982aab8751f507e1c33c6ae40c02
git rev-list --merges 3470d2f0fc9111590afe8d8b7adb84f312c4ceee..b14a068cdabb982aab8751f507e1c33c6ae40c02
git diff --name-only 3470d2f0fc9111590afe8d8b7adb84f312c4ceee..b14a068cdabb982aab8751f507e1c33c6ae40c02
```

Required results:

- Commit count: `37`
- Merge list: empty
- Changed product/test paths: exactly the nine paths in the manifest

### 4. Merge once with no fast-forward

Merge the approved feature branch once using the repository-required
no-fast-forward integration strategy. Do not cherry-pick the 37 implementation
commits separately.

If Git reports any conflict in a Cursor-owned file:

- Abort the merge.
- Do not edit conflict markers in the integration worktree.
- Identify the overlapping owner or stale integration baseline.
- Return the correction to the owning feature branch as a new atomic commit.
- Repeat founder approval and remote readback.

Codex backend/auth lanes are forbidden from modifying `ui_v2`; a UI-source
conflict is an ownership or baseline failure, not a routine manual-resolution
task.

### 5. Run combined verification

Minimum frontend replay:

```powershell
flutter analyze --no-pub `
  lib/ui_v2/buy/buy_v2_screen.dart `
  lib/ui_v2/buy/buy_v2_shop_chat.dart `
  lib/ui_v2/social/social_v2_consumer.dart `
  lib/ui_v2/universal/mool_contextual_chat_v2.dart `
  test/ui_v2/buy/buy_v2_shop_chat_test.dart `
  test/ui_v2/social/social_v2_contextual_chat_test.dart

flutter test --no-pub test/ui_v2/buy/buy_v2_shop_chat_test.dart
flutter test --no-pub test/ui_v2/social/social_v2_contextual_chat_test.dart
flutter test --no-pub test/ui_v2/buy/uaw_personal_mvp_buy_local_tabs_global_dock_c10c_test.dart
flutter test --no-pub test/ui_v2/universal/uaw_personal_mvp_chat_global_dock_exact_return_c10d_test.dart
flutter test --no-pub test/chat_flow_test.dart
flutter test --no-pub test/chat_production_gateway_test.dart
flutter test --no-pub test/chat_photo_attachment_test.dart
```

Also replay backend tests for every enabled capability, identity transition,
live provisioning, retry, thread removal, reply, Forward, reaction, offline
failure, process death and authenticated relaunch.

Run `scripts/check-approved-ui-locks.ps1`, the applicable integration
regression-memory gate, and the repository's combined regression suite. A
single failure blocks the candidate; do not weaken or bypass the test.

### 6. APK remains separately authorized

Do not build an APK immediately after merge. The successor APK requires a
founder-approved integrated commit, clean integration worktree, exact remote
readback, combined regressions, machine-gate state, source fingerprint,
runtime-define allowlist and separate one-build authorization.

## Final decision

The Cursor product implementation is ready for founder-reviewed integration at
`b14a068cdabb982aab8751f507e1c33c6ae40c02`.

Integration remains blocked until the documentation-only handoff successor is
committed, pushed and proven equal to the remote feature branch. Cursor must
remain unchanged after that handoff until the founder supplies a new integrated
baseline.
