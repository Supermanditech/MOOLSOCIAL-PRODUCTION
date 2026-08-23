# Personal MVP global Mool bottom-rail navigation audit

Date: 6 August 2026
Parent: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1`
State: `FOUNDER_AUTHORIZED_AUDIT_CHILDREN_SEQUENTIAL_DEVICE_REQUIRED`

## Production navigation rule

Mool is the stable Personal main-action home/hub. It is not an alias for
Social, an in-place main-action ribbon, a command palette or a modal menu.
Every off-hub Mool control opens the existing native Mool hub above the exact
current context. Back from that hub returns to the exact unchanged context.
On the hub, selecting Social, Buy, Eat, Ride, Book or Work opens that main
action; its own rail continues to expose only its valid sub-actions plus Mool
and Chat.

The root Mool control is the already-selected Home control. Retapping it does
not open a menu or reset state. Main actions remain visible in the hub body.

## Real-user use cases and Codex disposition

| ID | Starting context | User action | Required result | Back result / exception | Codex view |
|---|---|---|---|---|---|
| U01 | Mool hub | Tap selected Mool | Remain on the hub; no menu, route or lifecycle reset | Existing root Back policy remains | Required conventional selected-tab behavior |
| U02 | Mool hub | Tap Social, Buy, Eat, Ride, Book or Work | Open the exact main-action root once | Back returns to the same hub | Core MVP navigation |
| U03 | Social Shorts/Videos/Feed/Create or content depth | Tap Mool | Push the Mool hub without replacing Social state | Back restores exact tab, item and retained scroll where the owner supports it | Current toggle/back trap is a confirmed defect |
| U04 | Buy Shop/Wholesale/Medicine/Orders or nested product/cart/checkout/order state | Tap Mool | Push the Mool hub without replacing cart/order/session state | Back restores exact Buy state | Current rail replacement and Social fallback are defects |
| U05 | Eat chooser or Order Food/Book Table depth | Tap Mool | Push the Mool hub; do not clear notices, basket or booking state | Back restores exact screen | Current modal panel is rejected |
| U06 | Ride chooser, Bike, Auto, Cab or active trip | Tap Mool | Push the Mool hub; retain selected type and active trip | Back restores exact type/trip; conflicting type still uses the existing notice | OPPO reproduced the escaped defect here |
| U07 | Book chooser, Doctor or Salon depth | Tap Mool | Push the Mool hub; retain booking state | Back restores exact screen | Current modal panel is rejected |
| U08 | Work chooser, Earn Today, Workspace or active work depth | Tap Mool | Push the Mool hub; retain opportunity/workspace state | Back restores exact screen | Current modal panel is rejected |
| U09 | Global Chat inbox | Tap Mool | Push the hub over the exact filtered inbox | Back restores the filter and scroll where retained in memory | Current `go` destroys route context |
| U10 | Chat thread/composer | Tap Mool | Push the hub without clearing draft/reply/attachment state | Back restores the exact thread/composer; process-death draft persistence is not newly promised | Required global-Chat continuity |
| U11 | Shared Activity/Account/Spaces/Controls | Tap Mool | Push the hub rather than routing to Social | Back restores the exact shared screen | Current Social alias is a confirmed defect |
| U12 | Any main action | Tap a different sub-action | Stay inside that main action and open the exact valid sub-action | Back follows that owner's internal depth before leaving the main action | Sub-actions never masquerade as main actions |
| U13 | Any main action | Retap active sub-action | Do not recreate an order, trip, booking, cart or workspace owner | No history entry is added | Lifecycle safety requirement |
| U14 | Main-action nested depth | Android gesture/system Back | Close IME/transient UI first, then internal depth, then return to the hub if pushed from it | Never open a Mool menu as a Back side effect | Current Social behavior violates this |
| U15 | Mool hub pushed from an origin | Header or system Back | Pop to the exact origin | Direct/deep-linked hub with no stack must not invent Social as an origin | Deterministic history rule |
| U16 | Direct/deep-linked main-action route with no stack | Back at its root | Use its recorded safe return if present, otherwise the Mool hub | Never default to Social merely because history is absent | Required recovery rule |
| U17 | Offline/error/retry state | Mool then Back | Preserve the visible truthful state and retry owner | No fake success or reset | Robust MVP requirement |
| U18 | App switch, lock/unlock, call interruption or process recreation | Resume | Preserve or canonically restore the supported route/state per existing lifecycle owners | Ephemeral overlays may close; authoritative cart/order/trip/booking/workspace state must not reset | Device regression requirement |
| U19 | Postponed Pay/Tiffin/Get It Done/universal Delivery-Onboard-Verify | Inspect main/sub-actions | They remain absent or dependency-held under existing contracts | Navigation work cannot reactivate them | Explicit MVP exception |
| U20 | Provider-owned WebView/external provider surface | Provider UI active | Mool rail is not fabricated inside provider UI | Provider return restores its owning native route | Protected-runtime exception |
| U21 | Compact width, large text, TalkBack or reduced motion | Use rail/hub | All targets remain reachable, semantic, selected-state truthful and finite-motion | Reduced motion resolves immediately | Production accessibility gate |
| U22 | Rejected/old APK evidence | Start successor | Preserve APK, installed checksum, frames, XML and logs | No uninstall/data clear/downgrade | Release-evidence rule |

## Source-owner findings

- `SocialUniversalV2` stores `_moolOpen`; Mool toggles the centre rail between
  sub-actions and main actions, while Back sets `_moolOpen = true`.
- `_BuyDock` stores `_showPrimaryActions`; Mool replaces the Buy sub-action
  rail and Social is opened with `openMool=1`.
- `JourneySession.buyExitRoute` defaults to `/app/social?openMool=1`.
- Personal root, chooser and Eat/Ride/Book/Work rails call
  `showPersonalMoolActionPanel`, a modal interaction rejected by the founder.
- shared account Mool explicitly routes to `/app/social`.
- Chat inbox/thread Mool uses `go('/app/mool')`, discarding exact route-stack
  continuity.
- production navigation mixes `push`, `go`, modal dismissal and state-local
  toggles for the same Mool concept.

Source evidence is retained in
`artifacts/quality/uaw-personal-mvp-main-subaction-bottom-panel-fix1-20260806-01/59-global-mool-source-inventory.log`.

## Sequential child tickets

Only one child may be active at a time.

1. `...-C01-CONTRACT-REGRESSION-GATE`: freeze this matrix, permanent
   regressions and a machine gate. No runtime change or APK.
2. `...-C02-PERSONAL-HUB-EAT-RIDE-BOOK-WORK`: remove the modal owner; make
   root/chooser/Eat/Ride/Book/Work Mool behavior use the stable hub and exact
   stack return. No Social or Buy runtime change.
3. `...-C03-SOCIAL-RAIL-BACK`: remove Social's main-action rail mode; Mool
   pushes the hub and Back respects content depth then route history. Protected
   Social content/provider behavior stays unchanged.
4. `...-C04-BUY-RAIL-BACK`: remove Buy's main-action rail mode and Social
   fallback; Mool pushes the hub while cart/order state and Buy sub-actions
   remain unchanged.
5. `...-C05-CHAT-SHARED-RETURN`: make Chat inbox/thread and shared account
   Mool transitions preserve exact return context.
6. `...-C06-PROFILE-PROVENANCE-CUMULATIVE-OPPO`: repair the profile review
   marker, run all gates twice, consume one new unique build authorization,
   install in place and replay U01-U22 from the OPPO screen.

Workspace-specific Captain, Creator, Manufacturer, Retailer and Operations
docks are recorded in the global inventory but are not silently folded into a
Personal ticket. Their acceptance tickets must retain exact user/workspace
types under the repository rule; legacy Pay and legacy presentation owners
remain contained and cannot be reactivated by this batch.

## Scope

Classification: `mvp_required`, because this fixes confirmed navigation and
release-qualification regressions across supported Personal MVP journeys.
Reuse: the existing Mool hub, existing routes, sessions, sub-action docks,
Social/Buy owners and Chat return query. New screens, named routes, backend
owners, providers and persistent product state are prohibited.

No child authorizes credentials, provider writes, live messages/calls,
payment/funds, Production, commit, push, deployment, promotion, screenbook
mutation, OPPO uninstall/data clear/downgrade or protected content changes.
