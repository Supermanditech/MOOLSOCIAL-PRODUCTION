# UAW-CURSOR-SHOP-CHAT-UI-20260824

Founder date: 24 August 2026 IST
Lane: `cursor_ui`
Claim: `cursor_ui/shop_chat/implementation`
Branch: `work/cursor-ui/shop-chat-ui-20260824`
Accepted product and implementation base:
`ee5aa07ac8ec29e102832e84991ab7ec421da808`

## Customer outcome

Improve Chat only inside the Shop family so it feels compact, familiar and
native to MoolSocial. Shop, Wholesale, Orders and Offers now open one local
Shop Chat surface with contextual content, directional navigation motion and
an exact return path. The local UI now covers the full inbox-to-partner-to-
conversation journey, composition, inline sharing, conversation utilities and
commerce return paths. Runtime actions use a typed frontend seam and continue
through the unchanged production Chat callback when no specialized handler is
provisioned.

## Baseline and references

- Founder-provided r60.90 APK:
  `moolsocial-social-auth-r60.90-20260824.apk`.
- Founder-provided APK SHA-256:
  `828CE17A6C0416D02AF028977454B62C9DC39C8E67F29E16077B1B2E2E1EB541`.
- Current MoolSocial Shop-to-Chat OPPO reference:
  `apps/mobile/test/ui_v2/buy/candidate_captures/shop-chat-reference-current-moolsocial-oppo.png`.
- Current-reference dimensions: `720 x 1612`.
- Current-reference SHA-256:
  `73B5D94C469175840054B2C33B175D96B024228E92D15094DF342998E198D4A8`.
- A WhatsApp Business inbox was inspected on the connected OPPO only for
  information density, hierarchy and interaction familiarity. Because that
  reference contained private contact data, it is excluded from Git and from
  review artifacts.
- The live WhatsApp composer was inspected again after founder review. The
  resulting MoolSocial composer uses the same interaction structure--one wide
  message capsule containing emoji, file and camera controls, with only the
  mic/send control outside--but retains MoolSocial styling and Shop context.

## Implemented scope

- Full-depth visual revision: the active Shop context now persists through the
  inbox banner, new-conversation header and category badges, thread breadcrumb,
  commerce card, inline sharing, search, information and message-action states.
  MoolSocial navy remains the action language while restrained participant and
  context accents improve scanability without creating a separate visual brand.
- Added a compact Shop-native Chat header, contextual search, All/Orders/
  Partners/Offers filters, secure-conversation guidance, dense truthful rows
  and a 44-pixel new-chat action.
- Shop opens the combined view; Orders and Offers open their matching filters;
  Wholesale opens the partner filter.
- New conversation remains a full Shop Chat surface and offers relevant retail,
  wholesale, manufacturer, order and offer entry points. It never uses a
  popup.
- A selected entry opens a native conversation with partner identity, direct
  voice/video actions, commerce context and an exact route back to its Shop
  family origin.
- Every Shop Chat depth is a standalone full-height surface. The shared
  Mool/Shop/Wholesale/Orders/Offers/Chat destination rail is removed from the
  widget tree while Chat is active; the composer owns the bottom safe area.
  Closing Chat restores the exact prior Buy destination and its rail.
- The composer follows the reviewed OPPO structure: one wide rounded capsule
  contains emoji, editable text, the inline-share control and a one-tap camera;
  the mic changes to Send only when a draft exists. Every control remains at
  least 44 logical pixels.
- The file control expands an in-conversation tray immediately above the
  composer. Its second tap dispatches the exact document, camera, photo/video,
  product, order, location or contact intent. No modal or bottom sheet is used.
- Emoji/reaction choices, thread utilities and selected-message actions stay
  inside the conversation. Search is an inline field, thread utilities are an
  inline strip and long press replaces the header with Reply, React, Copy and
  Forward actions.
- Conversation info is a full local surface with partner role, voice/video,
  current commerce context, shared media, notification and safety entry points.
- Authoritative messages can render text, image, video, document, voice,
  product, order, location and contact forms with reply, reaction and delivery
  metadata. The production default deliberately supplies no invented message
  history.
- Back and system Back return to the exact originating Shop-family surface
  one depth at a time--info to thread, thread to inbox, inbox to origin--without
  replacing session state.
- Switching Shop-family subactions closes the local Chat surface and uses the
  existing Buy navigation path.
- Opening, closing and changing Shop Chat surfaces use finite directional
  fade-and-translate motion. Row and filter transitions are finite and respect
  reduced-motion accessibility settings.
- All interactive targets maintain at least 44 logical pixels. The layout is
  covered at 320, 390 and 430 logical-pixel widths and at 140 percent text
  scaling.
- Order rows use existing session order records. Seller, wholesale and offer
  rows are conversation entry points, not fabricated messages or replies.
- A public `BuyV2ShopChatProvisioningSource` supplies authorized threads and a
  typed `BuyV2ShopChatActionHandler` receives runtime intents. These are the
  clean connection points for future retail, wholesale and manufacturer
  workstation provisioning and transport services.
- Send clears its draft only after an accepted runtime result. Rejected or
  unavailable sends retain the draft and show truthful recovery. The UI does
  not fake send, delivery, unread, timestamp, upload, call or runtime-success
  state.

## Backend connection points for later tickets

The frontend contract is ready; the following production services remain
backend/provider work and were intentionally not implemented here:

- authorized actor, organization and thread provisioning for retailers,
  wholesalers and manufacturers;
- message-stream pagination, idempotent send, delivery/read state, failure,
  retry, reconnect and offline-queue reconciliation;
- file/media picking permissions, upload limits, malware scanning, private
  object storage, expiring access, transcoding and thumbnails;
- voice recording/upload and voice/video RTC signalling, permissions and call
  lifecycle;
- push notification, presence and read-receipt delivery;
- product, order and offer reference authorization and visibility checks;
- retention, encryption, moderation, block/report, safety and audit controls.

The screenshot-only rich conversation fixture exercises the rendering
contract. It is not the production provisioning source and cannot create a
fake runtime success.

## Explicit exclusions

No global Chat, Social, authentication, provider, server, Android/iOS,
platform, Firebase, signing, configuration, dependency, script, release,
deployment, policy, registry or unrelated screen owner changed. No APK was
built or installed for this screenshot-review stage.

## Focused verification

- Targeted Flutter analysis across the five Shop Chat source/test owners:
  pass, no issues.
- `buy_v2_shop_chat_test.dart`: pass, `14/14` tests.
- Combined Buy screen, navigation-motion, Shop Chat and contextual Chat run:
  pass, `99/99` executed tests; one capture generator skipped by default.
- Explicit candidate-capture run: pass, `1/1` test.
- All enhanced candidate screenshots are `390 x 844`:

| State | SHA-256 |
| --- | --- |
| `shop-inbox` | `3318FA95CE4FC6794DB313B56DD8419647A43C12E7A7C284BD0534144905349E` |
| `orders-inbox` | `6845FE53CB24D48D8D356CBF56B3040AA96F54195C0130D7C7199B6CC365BD2E` |
| `offers-inbox` | `5B1C78F05F17846846647AA460404B6C4BE19383ED759DE4AC70CEE7F76732C2` |
| `partners-inbox` | `51F584F484FD1F7DD5AB02F4BBEBFCD487897C90C695B6BDA9E378B1CCF94B2F` |
| `new-conversation` | `4FC6466409292F17D1F771E3731F7F688A3CF3E680E73751FE067BC5BEEA862C` |
| `conversation` | `50A34ACA310B0398828F7B9AA8F2B2429BAEACFE6A3CD519BA266FA54452E1DD` |
| `composer-draft` | `7C78FCFD62622E36546A602676CFA812EF9558E55B2D2FD1164F664058F98031` |
| `emoji-tray` | `A4A33D87E98333AC5467BDA799CE574C2EA994A2A2E15CE82E117192FF612175` |
| `attachments` | `F5FF0C5EE87C4512C210A747461679FEB28B2509DF7D1217421A2A540BFF2210` |
| `thread-menu` | `E2ADFADFA82A79E396006B52C657C65B0B77A9D62CD173791288DE4012216356` |
| `conversation-search` | `D862926DA251A86E7D0F0CC317C88BA3B5262E9254C08DE89CB84E98DE5EAA92` |
| `business-info` | `A647C3C85F50852F9F9987FA50369B0445D8F4923C0C01B986A7170D0922F470` |
| `message-actions` | `3CA4BD3A2E14CA2CDF77CC04C30FD55597EDC9A38D3E1701CF173E6F6F36D296` |

## Approval state

The laptop candidate is ready for founder UI/UX review. APK integration,
installation and OPPO approval remain pending a later explicit step.
