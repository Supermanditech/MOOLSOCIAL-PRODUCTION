# UI-CONFORMANCE-003 — private Screen 04 difference contract

Date: 20 July 2026  
Visibility: evidence only; this file must never be rendered in customer HTML  
Status: founder-rejected candidate correction contract

## Authority

1. Founder rejection and correction instruction dated 20 July 2026.
2. Production memory and QA-024.
3. `approved-final/screens/04-universal-focus-shell.html`.
4. Screenbook commit
   `2febd426c7ea254292c1e822221efc00b08a82f3`.
5. Approved brand and shared-foundation sources.

The approved-final Screen 04 and the Screen 04 blob at the pre-remake commit
have the same Git blob:

`461bafa66aa773490ccc578680e0d1906ce1cb64`

Approved-final Screen 04 SHA-256:

`A64D4D6819892803BF0FAF86C13B81933D36D7B12D7FCCE8BC96E0AD455AF313`

Rejected candidate SHA-256:

`9D4BBC76104CB5208F54FDFD83603D89EE563BF0A0CDBB724249F1C27FCD9B86`

The founder's current whole-page copy instruction supersedes the older
approved file's visible screenbook/documentation wrapper. Its in-phone
information architecture remains the design authority.

## Composition difference

### Rejected candidate

- Uses a wide founder-review document with a separate phone preview and
  visible preview-state side panel.
- Opens with a greeting and a permanent eight-tile dashboard for Social, Buy,
  Eat, Ride, Book, Pay, Work and Chat.
- Places a generic focus card below the dashboard.
- Uses a two-item bottom row containing only Mool and Chat.
- Opens Mool as another sheet containing a tile grid.
- Removes the approved focused content surface and contextual content-action
  rail.

### Required approved architecture

- The whole pathname renders only the finished customer product edge to edge.
- Universal opens directly in Social with Shorts selected.
- The approved navy MoolSocial header and command bar remain above content.
- The focused sub-action strip is immediately above the active content.
- Exactly one product/service action is focused at a time.
- The focused action owns the visible product/service content placement.
- A contextual content-action rail belongs beside the active content.
- The floating Apple-inspired outcome dock keeps Mool stable at one edge and
  Chat stable at the other edge.
- The dock middle is the focused action's contextual sub-action rail.
- Opening Mool temporarily replaces only the middle rail with Social, Buy,
  Eat, Ride, Book, Pay and Work.
- Selecting Mool or a focused sub-action restores content focus without
  creating an eight-tile dashboard.
- Chat opens in one tap and carries a direct return to the previous focused
  action.

## Main actions, sub-actions and placement contract

| Main action | Approved focused sub-actions | Default | Approved placement |
| --- | --- | --- | --- |
| Social | Shorts, Videos, Feed, Create | Shorts | Social media/content surface with contextual Like, Comments/Reply, Share, Remix/Save/Post actions |
| Buy | Grocery, Categories, Medicine, Basket | Grocery | Decision-ready product/household content; Fresh, Monthly and Nearby are nested Grocery choices |
| Eat | Order Food, Book Table, Tiffin | Order Food | Decision-ready meal, table and tiffin content |
| Ride | Bike, Auto, Cab | Bike | Pickup/fare/vehicle content |
| Book | Get It Done, Doctor, Salon | Get It Done | Defined task and appointment content; Salon, Repair and Laundry remain nested service choices where applicable |
| Pay | Recharge, Bills, Scan & Pay, Receipts | Recharge | Payment/recharge/receipt content |
| Work | Earn Today, Delivery, Onboard, Verify, Workspace | Earn Today | Funded work, proof, payout and workspace content |
| Chat | People, Business, Orders, Support | People | Separate one-tap Chat destination with return to the previous action |

### Missing or moved in the rejected candidate

- Social sub-actions remain links but are moved out of the approved focused
  strip and content context.
- Buy loses the approved Grocery, Categories, Medicine and Basket hierarchy;
  it substitutes Shop nearby, Search products and Saved baskets.
- Eat labels are present but are moved into a generic focus card rather than
  the focused strip/content surface.
- Ride labels are present but are moved into a generic focus card.
- Book adds All bookings and removes the approved three-item focused
  hierarchy as the sole strip.
- Pay labels are present but are moved into a generic focus card.
- Work replaces Earn Today, Delivery, Onboard, Verify and Workspace with Earn,
  My Work, Add work and Explore Work.
- Chat loses People, Business, Orders and Support as a focused context and is
  reduced to a generic destination.
- Social Create nested Text, Short and Video choices are absent.
- Social Short Record, Caption and Post choices are absent.
- Buy Grocery nested Fresh, Monthly and Nearby choices are absent.
- Book service nested Salon, Repair and Laundry choices are absent.
- Contextual rails for Like, Comments/Reply, Share, Remix, Save, Compare,
  Chat, Apply, Proof, Accept, Scan and Help are absent or displaced.

## Bottom-rail difference

### Rejected

- Two equal bottom buttons: `Mool · All actions` and `Chat`.
- No centered focused-action rail.
- Mool opens a full sheet with seven tiles.
- Main action selection is duplicated by the permanent eight-tile dashboard.

### Required

- One floating material dock with three regions:
  `Mool | focused context | Chat`.
- Mool and Chat never move.
- The middle rail shows readable contextual sub-actions.
- Mool temporarily replaces only the middle rail with the seven root actions.
- Four-or-fewer context actions fit without clipping; larger sets scroll.
- All targets are at least 44×44 and remain reachable with text scaling.

## Branding difference

### Rejected

- Improvised `M` initial tile.
- Altered navy `#06066F` and `#12128C`.
- Altered saffron `#FF921F`.
- Altered green `#14883F`.
- One-off ink, warm, danger and shadow palette presented as the product
  identity.
- No approved tricolour identity line under the MoolSocial wordmark.

### Required

- Exact navy `#000080`.
- Exact saffron `#FF9933`.
- Exact green `#138808`.
- White `#FFFFFF`.
- Joined `MoolSocial` wordmark, wordmark-first.
- Approved saffron/white/green identity line in proportions 45/14/41.
- No `M` icon, `MS` monogram, mascot or alternate brand mark.
- Shared Inter/system typography, restrained material, 8px product surfaces,
  pill controls, short explanatory motion and reduced-motion support.

## Visible prohibited copy in the rejected candidate

The following visible or semantic strings must not survive the correction:

- Browser title: `04 Universal - MoolSocial Screenbook`
- `Screen 04 · Founder review`
- `Awaiting founder decision`
- `A calm signed-in home for Social, Buy, Eat, Ride, Book, Pay, Work and Chat,
  with the customer’s serviceable area kept close at hand.`
- Semantic label: `Screen 04 Universal founder review`
- Semantic label: `Preview other customer moments`
- `Preview other moments`
- `Choose a moment below to see the customer-facing recovery and next action
  inside the phone.`
- `Return to Universal`

The complete visible review/test selector set must also be removed from the
page:

- Search selectors: `Looking`, `Nothing found`, `Not available`,
  `Couldn’t load`, `Trying again`, `Results`.
- Camera selectors: `Camera access off`, `Camera unavailable`,
  `Code not read`, `Code found`.
- Voice selectors: `Microphone access off`, `Voice unavailable`,
  `Speech not heard`, `Request heard`.
- Notification selectors: `Checking`, `All caught up`,
  `Phone alerts off`, `Not available`, `Couldn’t load`, `Recent updates`.
- Serviceable-area selectors: `Looking nearby`, `No match`,
  `Location access off`, `Area not served`, `Couldn’t load`,
  `Trying again`.

The older approved-final documentation wrapper also contains visible
screenbook, draft, contract, API and implementation language. It is not copied
into the customer page. Only its in-phone architecture, action inventory,
placement and interaction model are carried forward.

## Correction acceptance

- Entire visible page is finished customer UI.
- `founderReview=1` changes no visible content.
- Approved wordmark, identity line and exact colours are present.
- Default state is Social / Shorts.
- One world and one focused sub-action are active.
- Focused content, sub-action strip and contextual action rail match the
  approved hierarchy.
- Bottom dock preserves Mool/context/Chat geometry and behavior.
- Every main, sub, nested and contextual action has an observable state or
  declared destination.
- Search, scan, voice, account, permanent serviceable area and notification
  states use customer language.
- Whole-page copy, interaction, fitment, brand and Screen 01–03 lock gates pass.
- The resulting HTML remains a founder-review candidate until explicit HTML
  `FINAL`.
