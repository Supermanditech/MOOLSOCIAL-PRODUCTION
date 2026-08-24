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
- Combined Buy screen, navigation-motion and Shop Chat run: pass, `94/94`
  tests.
- Explicit candidate-capture run: pass, `1/1` test.
- All enhanced candidate screenshots are `390 x 844`:

| State | SHA-256 |
| --- | --- |
| `shop-inbox` | `FFB4B2B771F22176A0BD66C0BE736B983F26143999AD5236CF67B4128F872630` |
| `orders-inbox` | `AC24785EF548E6E7BCA2BEE05F0A52620DD30C93D260DE9F4EDA2B8F071D3C2F` |
| `offers-inbox` | `2419E02CA9319DA8E57384914B1E81BA1A65530BF20DFF5E241C8043A8E0DDCA` |
| `partners-inbox` | `C019CE699D4C896D67586C12866433F44BFF04E49D6BC07EC27E8E109B60AC14` |
| `new-conversation` | `74B5071D58682CF17340DB95DE0CAF2082FBD836EEBCE92C38D4D7DB9308F2E8` |
| `conversation` | `D71EC398FACE3C4B6AB878F5CDE2E04EC7529A6A7022375F70C3240E962EE57C` |
| `composer-draft` | `877B2A41ECF0AA6F22D195B0C8930F97A49584DE071B49892B5C5CE9A0AE16C0` |
| `emoji-tray` | `8CEEBD5E1EE4993E151D0131DDBB3B81E79736F6E173639B21EAEC2E3AF6F60C` |
| `attachments` | `FC0E082D0550654A94D47A9C678326D61AAC4AC02551A7A3226C4717F48F9B4F` |
| `thread-menu` | `456CBF147F89F5BCB910884CE9A5FA60D7B6ABFDA1EE06F5F7138C1F00B58927` |
| `conversation-search` | `D3FC54AE614C8DEDCAC3BA77DB81779C4F9F1557477C4021C77D7B8C3D73C7A2` |
| `business-info` | `65B58AC4558BB177768B91B61C7954AC2532BEF976CD7EB581CD9A7481F64055` |
| `message-actions` | `89BD29D883173ECF94F4EE1F6394BB36217A27EA61B471D0737F9E110511E86A` |

## Approval state

The laptop candidate is ready for founder UI/UX review. APK integration,
installation and OPPO approval remain pending a later explicit step.
