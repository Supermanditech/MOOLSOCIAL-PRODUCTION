# Founder tickets: Universal navigation, action discovery and Buy

Status: **FND-U04-ACTION-003 SOCIAL MAIN-ACTION HTML IN PROGRESS**

Recorded: 21 July 2026

This ticket pack records the founder's next UI/UX direction. It is a successor
to the older local-demo `NAV-001` and `BUY-001` work. Their historical
completion does not satisfy these production-bound founder tickets.

## Current checkpoint

- Production repository:
  `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Required branch:
  `remediation/prototype-conformance-2026-07-20`
- Production repository HEAD observed while recording these tickets:
  `725c84607a3ec532bf3eb653e93ee55c78693cdc`
- Screenbook:
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook`
- Screenbook Git state observed while recording these tickets: branch `main`,
  HEAD `2febd42`, with pre-existing working-tree changes in Screens 01–04.
  Preserve all four changes; the future authorization permits editing only
  Screen 04 during the rail cycle.
- Current Screen 04 founder-review candidate:
  `screens/04-universal-focus-shell.html`
- Screen 04 current Social main-action SHA-256:
  `C815CEF2574A9BB7D2596DBE156BFE8549B8C3869DE5E2994B072668FAA8F855`
- Founder-review URL:
  `http://127.0.0.1:8765/screens/04-universal-focus-shell.html?founderReview=1&rail=capability`
- Current status: the capability bottom rail is founder accepted; the Social
  main-action HTML is the active founder-review slice. Screen 04 is **not
  founder `FINAL`**, not frozen, not in the approved-reference manifest and not
  authorized for Flutter.
- Existing screenbook filenames:
  - Screen 04: Universal
  - Screens 05–08: Social Shorts, Videos, Feed and Create
  - Screen 09: Buy

## Absolute boundaries

1. Do not start any ticket until the founder says `continue`.
2. Screens 01–03 remain immutable. Preserve all tracked and untracked evidence.
3. Work on HTML first. Do not change Flutter UI until the exact connected HTML
   checkpoint is explicitly marked `FINAL`.
4. Do not freeze a reference or update the approved manifest before `FINAL`.
5. Do not start Screen 05, Screen 09 or another downstream HTML file merely
   because the Screen 04 rail is being reviewed.
6. Customer-visible copy must contain finished, professional, actionable
   product language. No commentary, example, review, prototype, engineering,
   route, state, workflow or implementation wording may appear.
7. Apple-inspired means calm hierarchy, direct manipulation, short meaningful
   motion, predictable navigation and accessible targets. It does not authorize
   copying Apple assets or weakening MoolSocial branding.
8. The two-tap objective means that the user reaches a useful,
   decision-ready main/sub-action view within two taps. It must not remove
   legally, financially or operationally necessary confirmation steps.
9. Automated assertions do not overrule founder visual judgment.
10. The accepted Universal bottom rail is immutable during first-layer action
    design. Do not change its CSS, markup, labels, motion, interaction logic or
    navigation history without a new explicit founder instruction.
11. Native production implementation remains blocked until the first-layer
    HTML for Social, Buy, Eat, Ride, Book, Pay and Work has each received
    explicit founder approval.

## Founder outcome

From Universal, a first-time user must immediately understand that MoolSocial
supports Social, Create, Buy, Eat, Ride, Book, Pay, Work and Chat. The
navigation must require little effort, preserve maximum content space, support
both tap and direct slide/swipe interaction, and provide predictable backward
and forward movement between a main action, its sub-actions and the prior
context.

`Create` remains a Social sub-action in the information architecture. Because
Universal opens in Social, `Create` must still be discoverable in the first
view without incorrectly promoting it into an unrelated eighth main action.

## Execution order

| Order | Ticket | Outcome | Gate |
| --- | --- | --- | --- |
| 1 | `FND-U04-RAIL-001` | Founder-comparable bottom-rail directions | Founder selects one direction |
| 2 | `FND-U04-RAIL-002` | Selected rail implemented in Screen 04 HTML | Founder approves rail interaction |
| 3 | `FND-U04-ACTION-003` | Focused main-action and sub-action shell | Founder approves Universal action architecture |
| 4 | `FND-U04-QA-004` | Complete Screen 04 HTML verification | Founder marks Screen 04 `FINAL` or rejects it |
| 5 | `FND-BUY-HTML-005` | Decision-ready Buy HTML journey | Begins only after the Screen 04 gate |
| 6 | `FND-COPY-QA-006` | Complete customer-copy and interaction audit | No findings |
| 7 | `FND-NATIVE-007` | Matching isolated native Flutter V2 slice | Begins only after the applicable HTML `FINAL` |
| 8 | `FND-DEV-TRIAL-008` | Controlled real-service Trial decision and replay | Separate founder/cloud authorization |

---

## `FND-U04-RAIL-001` — Bottom-rail design directions

Execution checkpoint: **three directions were prepared and verified; the
founder selected the capability ribbon for correction**. Historical options
evidence:

`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-rail-001/FND-U04-RAIL-001-FOUNDER-OPTIONS-20260721.md`

### Objective

Prepare two or three genuinely comparable MoolSocial-branded rail directions
for founder review. Do not change the production Flutter UI.

Every direction must:

- make the breadth of MoolSocial understandable on first inspection;
- expose or clearly reveal Social, Buy, Eat, Ride, Book, Pay and Work;
- keep Chat one tap away;
- show Social sub-actions, including Create, in the default first view;
- support both tapping a named action and sliding/swiping to another action;
- make additional horizontally available actions visually obvious without
  using instructional commentary;
- preserve safe, familiar native Back behavior;
- use MoolSocial navy `#000080`, saffron `#FF9933`, green `#138808`, the
  approved joined wordmark and tricolour identity line;
- remain calm and content-first rather than becoming a dashboard grid;
- use no target below 44×44 logical pixels.

### Required directions

The alternatives may refine these patterns, but must not be superficial colour
variants:

1. **Capability ribbon** — a branded anchor with a readable horizontally
   scrollable list of all main actions and a stable Chat destination.
2. **Focused dock plus reveal** — stable Mool and Chat edges with the current
   action and a directly revealable capability ribbon.
3. **Direct-manipulation carousel** — the focused action is centred; adjacent
   actions visibly peek; swipe changes focus and tap opens the chosen action.

All directions must support both tap and swipe. Do not create a settings toggle
that forces the customer to choose only one navigation method.

### Founder review deliverable

- One exact browser URL per alternative.
- Identical viewport, content and state for fair comparison.
- A short non-customer-facing difference contract explaining space use,
  discoverability, gesture behavior, accessibility and navigation history.
- No engineering controls or review labels inside the customer viewport.

### Acceptance

- Founder explicitly selects one direction or requests a revision.
- No downstream action screen is started before this selection.
- Rejected alternatives remain evidence and are not represented as approved.

---

## `FND-U04-RAIL-002` — Selected Screen 04 rail

Execution checkpoint: **founder accepted 21 July 2026**. The
founder-directed capability revision is implemented in HTML; the oversized
arrow tiles and subsequent oval cues were replaced by bare subtle edge hints.
The accepted rail must not be redesigned during main-action work.
Evidence:

`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-rail-001/FND-U04-RAIL-002-SUBTLE-HINT-REVISION-20260721.md`

### Objective

Implement only the founder-selected rail direction in
`04-universal-focus-shell.html`.

### Interaction contract

- Tap a main action: focus that action and show its useful default content.
- Horizontal drag/swipe: move to the prior or next main action with a short,
  reversible transition.
- Tap a sub-action: open its decision-ready content or exact connected HTML
  destination.
- Back from a detail: return to its sub-action context.
- Back from a sub-action destination: return to the focused main action.
- Back from a changed main action: return through actual navigation history,
  without resetting unexpectedly to Social.
- Forward, when exposed by the selected design, restores the next known history
  entry; it must never guess or skip an action.
- Chat retains the action/sub-action return context.
- Native Android/iOS Back remains authoritative. Any visible Back/Forward
  controls must agree with it.
- Horizontal rail gestures must not steal vertical page scrolling or horizontal
  product/category gestures.

### First-look information contract

- Universal opens in Social.
- Social, Buy, Eat, Ride, Book, Pay and Work are named in the rail or are
  immediately revealed by an unmistakable direct manipulation.
- Shorts, Videos, Feed and Create are visible or immediately available in the
  separate Social sub-action treatment.
- The selected main action and selected sub-action are always visually and
  semantically clear.

### Acceptance

- Founder approves the rail's visual treatment, words, size, position, motion,
  tap behavior, swipe behavior and Back/Forward behavior.
- Compact devices, 140% text, keyboard and safe-area conditions do not hide
  the active action or Chat.
- No change is made to shared runtime/CSS unless separately justified,
  inventoried and founder-authorized.

---

## `FND-U04-ACTION-003` — Focused action and sub-action shell

Execution checkpoint: **authorized and in progress 21 July 2026**, beginning
with the Social main-action surface. Creator commerce is founder approved and
governed by
`docs/decisions/ADR-0003-CREATOR-COMMERCE-ATTRIBUTION-AND-PAYOUT.md`.

Current Social founder-review evidence:

`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/FND-U04-ACTION-003-SOCIAL-FIRST-LAYER-FOUNDER-REVIEW-20260721.md`

The latest creator-distribution revision is governed by
`docs/decisions/ADR-0004-CREATOR-CONTENT-DISTRIBUTION-AND-ANALYTICS.md`.
Machine evidence:

`artifacts/quality/screen04-html-founder-review-20260720/fnd-u04-action-003/screen04-social-distribution-audit-20260721-01.json`

### Objective

Use the approved rail to give each main action the maximum practical content
space while keeping navigation predictable and the customer's next decision
obvious.

### Main-action behavior

The first tap on Social, Buy, Eat, Ride, Book, Pay or Work must show a compact,
useful glimpse of what the customer can do there. It must not show generic
descriptions, filler cards, empty dashboards or implementation explanations.

The second tap chooses a sub-action, item, category or decision and opens the
corresponding content. A third tap is allowed only when needed to post, buy,
book, pay, apply, send, save or otherwise commit.

### Space and hierarchy

- Only one main action is focused at a time.
- Main actions and sub-actions are not compressed into one unreadable row.
- Sub-actions remain close to their associated content.
- Contextual actions use a compact rail/surface and do not cover key content.
- Rails or filters may collapse after a choice and remain easy to restore.
- Motion explains a focus change; it must not delay the customer.
- Reduced Motion receives an immediate, non-disorienting equivalent.
- The accepted bottom rail is the sole navigation owner for a focused action's
  sub-actions. Do not repeat the same sub-action words in a top chip row.
- Social opens with an immersive MoolSocial media item. Public discovery modes
  are `For You`, `Following`, `Nearby` and clearly disclosed `Promoted`.
  `Shorts`, `Videos`, `Feed` and `Create` remain solely in the accepted bottom
  rail and are not repeated above content.
- The accepted `Shorts` choice owns one Reel/Short vertical-video format. The
  accepted `Feed` choice owns text, single-image and carousel Posts. Creator
  format selection uses `Reel`, `Video` and `Post or Carousel` without separate
  Reel and Short choices.
- Watching is the visible media item itself. Like, Comment, Share, Remix and
  related controls belong to that individual item, never to a permanent
  page-level vertical rail.
- The Social main-action first impression must serve viewers, creators,
  individuals, businesses, advertisers, product owners and service providers
  without turning Universal into a dashboard grid.
- Creator-commerce claims must be based on eligible delivered sales, not views
  or other YouTube engagement metrics.
- Public Social never displays external networks as consumer-feed buttons.
  Creator distribution belongs under Profile/account and may design only the
  direct-API destinations in ADR-0004. Provider-specific account eligibility,
  explicit destination choice, partial success and analytics-source boundaries
  remain visible. Partner-only destinations stay absent until live.

### Acceptance

- Each main action communicates a useful first result without another
  explanatory screen.
- Every visible action has a concrete next state or destination.
- The complete path inventory distinguishes in-page focus changes from actual
  downstream files.
- The founder approves the shared action-shell behavior before Buy is expanded.

---

## `FND-U04-QA-004` — Screen 04 HTML candidate gate

### Required verification

- Exact URL, pathname, visible heading and primary content.
- Every visible tap, sub-tap, nested tap, swipe, Back, Forward, Close, Cancel
  and Chat-return path.
- Default, selected, empty, loading, unavailable, denied, failure, retry and
  restored-history states where reachable.
- `320×568`, `360×640`, `360×720`, `375×667`, `390×844`, `412×915` and
  `430×932` at 100% and 140% text.
- Keyboard, safe-area, screen-reader, Reduce Motion and loss-of-focus behavior.
- No clipped labels, horizontal page overflow, hidden active state, gesture
  collision, dead control, console error or customer-copy finding.
- Screen 01–03 lock script before and after the work.
- Exact final HTML SHA-256 and changed-file inventory.

### Gate

Stop and present the exact Screen 04 HTML for founder visual review. The
founder's approval of Social advances work only to the next main first-layer
HTML. Native Flutter V2 may begin only after every main first-layer screen has
been explicitly approved and the founder separately authorizes production
implementation.

---

## `FND-BUY-HTML-005` — Compact retail and wholesale Buy journey

### Start gate

Do not begin until the Screen 04 rail and action-shell gates are founder
approved. Before editing, inspect the current Screen 09 HTML, all of its states,
and every connected Buy destination. Do not assume the existing file already
matches this ticket.

### Universal-to-Buy contract

- First tap: `Buy` reveals real product/category value immediately.
- Second tap: the customer chooses a product, category, shop, pack or filter
  and reaches a decision-ready view.
- Further taps are used only for quantity, delivery, payment, regulated-item
  requirements or purchase commitment.

### Required compact Buy view

- A useful first product/category glimpse, not a marketing explanation.
- A category rail at the left or leading edge that can be swiped/collapsed
  after selection and restored without losing the selected category.
- Product tiles that prioritize:
  - product name and pack;
  - final price and comparable unit price;
  - retail or wholesale context;
  - availability;
  - delivery time;
  - shop/seller;
  - distance or service-area relevance when trustworthy;
  - the next clear action.
- Compact filters for:
  - price;
  - distance;
  - category;
  - shop/seller;
  - serviceable area;
  - delivery timing.
- Clear Retail and Wholesale choices without mixing their quantities, price
  rules or commitments.
- Wholesale choices show pack/case size, minimum quantity, quantity price
  breaks, applicable taxes, delivery terms and payment terms before commitment.
- Retail choices show customer pack, final price, delivery promise and
  cancellation/return information.
- Eligibility-dependent wholesale credit or payment terms are shown only when
  verified for that account; never imply approved credit that does not exist.
- Medicine or regulated goods preserve their legal and prescription
  requirements.

### Customer-facing action vocabulary

Prefer direct actions such as:

`Choose category`, `View products`, `Choose pack`, `Compare shops`,
`Filter`, `Add to basket`, `Buy wholesale`, `See delivery times`,
`Review payment terms`.

Do not expose internal phrases such as:

`mode`, `world`, `state`, `route`, `sample product`, `example pricing`,
`prototype filter`, `test seller`, `mock delivery`, `business logic` or
`provider response`.

### Founder review and freeze

- Present the exact connected Buy HTML states, not screenshots alone.
- Founder approval of Screen 04 does not automatically approve Buy.
- Freeze Screen 09 and its connected accepted states only after a separate
  explicit founder `FINAL`.
- Native Flutter Buy work begins only after that HTML freeze.

---

## `FND-COPY-QA-006` — Production language and complete-state audit

### Objective

Prevent the repeated regression where working notes, examples or technical
explanations appear in founder-review or production customer screens.

### Acceptance

- Mount and read every reachable visible state, not only the default state.
- Inspect rendered text, editable-field labels/hints and semantic labels.
- Every action says what the customer can do next.
- Every completion says what happened and where to find it.
- Every failure says what remains safe and offers a useful recovery action.
- No generic success, fake availability, hidden limitation or dead action.
- Copy remains readable at compact sizes and 140% text.

---

## `FND-NATIVE-007` — Isolated native Flutter V2 implementation

### Start gate

This ticket remains blocked until the applicable HTML checkpoint is marked
`FINAL`, frozen with assets, reference images, interaction contract and
checksums, and added to the approved-reference manifest.

### Required implementation

- Fresh isolated native Flutter UI V2 presentation.
- Reuse existing tested models, controllers/sessions, services, API adapters,
  authentication, native/Firebase configuration and business logic.
- Do not mix legacy and V2 presentation components.
- Do not use an HTML WebView.
- Compare HTML and Flutter at identical viewport, state and text scale.
- Replay every action and interruption path on the connected OPPO.
- Wait for founder `Accepted` or `Rejected`.

---

## `FND-DEV-TRIAL-008` — Real-service Trial timing decision

### Current environment

- Dev/Trial project: `moolsocial-dev-503018`
- Project number: `760290687711`
- Staging and Production remain outside this ticket.
- Local Firebase emulators remain the first boundary.

### Recommended split

Do not delay all authentication testing until every Social, YouTube, Reels,
Post and commerce screen is complete. Also do not connect unfinished HTML
screens directly to live services.

Use this staged boundary:

1. Continue HTML and native UI work against local emulators.
2. After Screen 04 has founder `FINAL` and the matching connected Flutter slice
   is accepted internally, request separate action-time authorization to
   register the Dev Android/iOS apps and restrict credentials.
3. Use Dev/Trial plus the Dev App Distribution Preview group to replay the
   locked Screen 01–03 authentication journey into the accepted Universal
   destination.
4. Enable only the authentication methods whose real provider setup,
   credentials, consent, failure behavior and account-linking paths are ready.
5. Add YouTube/social publishing APIs only with their corresponding accepted
   screen journey, restricted credentials, quotas and external-provider
   approval. YouTube connection is not treated as an independent Firebase
   identity provider.
6. Promote nothing to clean Staging until the defined connected candidate,
   affected journeys and two full regressions pass.

### Decision gate

The founder must separately authorize the credential-bearing Dev registration
and provider setup. This ticket creates no cloud resource, key, OAuth client,
provider secret, tester group or distribution release by itself.

## Morning start command

When the founder says `continue`, begin with `FND-U04-RAIL-001`. Before any
write:

1. verify both repositories' live branch, HEAD and status;
2. preserve every existing change and evidence file;
3. read all mandatory UI authority files from `AGENTS.md`;
4. run the Screen 01–03 lock gate;
5. verify the current Screen 04 SHA-256;
6. report any mismatch before modifying the candidate;
7. prepare the rail directions only.
