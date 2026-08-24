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
an exact return path. Any action that needs a real conversation continues
through the existing production Chat callback.

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

## Implemented scope

- Added a compact Shop-native Chat header, contextual search, All/Orders/
  Sellers/Offers filters, secure-conversation guidance, dense truthful rows
  and a 44-pixel new-chat action.
- Shop opens the combined view; Orders and Offers open their matching filters;
  Wholesale opens the seller/partner filter.
- Back and system Back return to the exact originating Shop-family surface
  without replacing its session state.
- Switching Shop-family subactions closes the local Chat surface and uses the
  existing Buy navigation path.
- Opening and closing Shop Chat uses finite forward/reverse fade-and-translate
  motion. Row and filter transitions are finite and respect reduced-motion
  accessibility settings.
- All interactive targets maintain at least 44 logical pixels. The layout is
  covered at 320, 390 and 430 logical-pixel widths and at 140 percent text
  scaling.
- Order rows use existing session order records. Seller, wholesale and offer
  rows are conversation entry points, not fabricated messages or replies.
- Header, row and floating chat actions all delegate to the unchanged
  production Chat callback. The UI does not fake send, delivery, unread,
  timestamp or runtime-success state.

## Explicit exclusions

No global Chat, Social, authentication, provider, server, Android/iOS,
platform, Firebase, signing, configuration, dependency, script, release,
deployment, policy, registry or unrelated screen owner changed. No APK was
built or installed for this screenshot-review stage.

## Focused verification

- Targeted Flutter analysis across the five Shop Chat source/test owners:
  pass, no issues.
- `buy_v2_shop_chat_test.dart`: pass, `7/7` tests.
- Combined Buy screen, navigation-motion and Shop Chat run: pass, `87/87`
  tests.
- Explicit candidate-capture run: pass, `1/1` test.
- Candidate screenshot:
  `apps/mobile/test/ui_v2/buy/candidate_captures/buy-v2-shop-chat-native-390x844.png`.
- Candidate dimensions: `390 x 844`.
- Candidate SHA-256:
  `813EB6617A0915FE1CCE41CA53C34702EFC351E77F8520419D2EC9E31A2467C8`.

## Approval state

The laptop candidate is ready for founder UI/UX review. APK integration,
installation and OPPO approval remain pending a later explicit step.
