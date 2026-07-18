# Universal entry and intent-completion production backlog

Status: **implemented and verified twice for the local production-demo scope**

Source of truth:

- Approved prototype screens `00` through `04` in
  `C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens`.
- Product design memory in
  `docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md`.

## Outcome

Deliver a production-grade Flutter journey from installation through the
Universal screen. Every visible main action, sub-action and necessary third tap
must either complete the user's intent or open the next complete user-facing
screen. No control may end in a generic toast when a real decision or completion
screen is required.

## Delivery definition

`main action -> focused sub-action -> item or decision -> completion`

The third level is used only when the user still needs to select or confirm
something. Like, Save, Follow and similar actions may complete immediately and
show their changed state on the same screen.

## Ticket order and status

| Order | Ticket | Outcome | Status |
| --- | --- | --- | --- |
| 1 | `DES-001` | App-wide Apple-inspired foundation and production language contract | Completed |
| 2 | `ENT-001` | Install, splash and boot UI plus retry/update paths | Completed for review build |
| 3 | `SET-001` | Language and area intent completion | Completed |
| 4 | `AUTH-001` | Provider, email OTP and mobile OTP intent completion | Completed for enabled mobile OTP |
| 5 | `UNI-001` | Universal header, search, profile, scan and voice actions | Completed |
| 6 | `NAV-001` | Replace the bottom rail with the Apple-inspired Mool navigation system | Completed |
| 7 | `SOC-001` | Social main action and every reachable nested action | Completed |
| 8 | `BUY-001` | Buy main action and decision-ready consumer paths | Completed |
| 9 | `EAT-001` | Eat main action and order/booking paths | Completed |
| 10 | `RIDE-001` | Ride main action and estimate/booking paths | Completed |
| 11 | `BOOK-001` | Book main action and service appointment paths | Completed |
| 12 | `PAY-001` | Pay main action and receipt-backed paths | Completed |
| 13 | `WORK-001` | Work main action and funded-opportunity paths | Completed |
| 14 | `CHAT-001` | Chat main action, transactional context and return navigation | Completed |
| 15 | `COPY-001` | Full visible-copy production-language audit | Completed |
| 16 | `QA-001` | First live black-box screenwise intent-completion audit | Completed |
| 17 | `FIX-001` | Fix every QA-001 defect and replay each exact failed tap sequence | Completed |
| 18 | `QA-002` | Independent clean-state full retest and final regression | Completed |

Completed ticket evidence:

- `DES-001`: `OUTCOME/DES-001-EVIDENCE.md`
- `QA-001` and `FIX-001`: `OUTCOME/QA-001-EVIDENCE.md`
- `QA-002`: `OUTCOME/QA-002-FINAL-REGRESSION.md`

The completion status above means the supported local review build exposes and
completes every defined user-facing interaction without a dead tap. It does not
claim that simulated commerce, fulfilment, payment or provider outcomes are
live. The production-provider and release blockers are recorded in
`OUTCOME/QA-002-FINAL-REGRESSION.md`.

## `DES-001` — Apple-inspired full-app foundation

### Scope

- Store the permanent full-app design rule in the repository.
- Add shared Flutter tokens for spacing, radii, material, shadow, motion and
  minimum tap size.
- Apply a consistent app theme to buttons, fields, sheets, dialogs, chips and
  page transitions.
- Keep MoolSocial identity colours without using large saturated areas where
  they compete with content.
- Add automated checks for critical tokens and prohibited internal wording.

### Acceptance

- Every new screen can be composed from the shared foundation without creating
  one-off visual constants.
- Tap targets are at least 44 x 44 logical pixels.
- Reduce Motion and text scaling do not block any action.
- Android and iOS use platform-appropriate transitions and system surfaces.
- No Apple trademark or copied proprietary asset is introduced.

## `ENT-001` — Install, splash and resilient boot

### Tap-depth contract

| Start | First tap/event | Second tap | Completion |
| --- | --- | --- | --- |
| Store listing | Install | Open | Splash starts |
| Splash | Automatic checks | — | Setup, Sign in, return destination or Universal opens |
| Offline boot | Try again | Automatic recheck | Correct destination opens |
| Unsupported version | Update app | Store opens | User can install supported version |

### Required states

Fresh install, returning signed-out user, returning signed-in user, safe deep
link, expired deep link, offline, timeout, retry, maintenance and required
update. Splash must never request sensitive permissions.

## `SET-001` — Language and area

### Tap-depth contract

| First tap | Second tap | Optional third tap | Completed intent |
| --- | --- | --- | --- |
| Language | Choose language | Continue | App copy uses the selected language |
| Use current location | Allow or deny system permission | Confirm detected area when ambiguous | Service area saved or a recovery choice shown |
| Enter area | Type locality or PIN code | Choose a suggestion | Service area saved |
| Skip for now | — | — | Sign in opens without requesting location |

### Required states

Empty search, no matching area, permission denied, permission permanently
denied, location unavailable, offline lookup, retry, change area and cancel.
The user must understand why area improves local results before any permission
request.

## `AUTH-001` — Sign in and account continuation

### Tap-depth contract

| First tap | Second tap | Optional third tap | Completed intent |
| --- | --- | --- | --- |
| Google / Apple / X / Instagram / Facebook | Choose/approve account on provider surface | Resolve account-link consent when required | Universal opens |
| Email OTP | Enter email and Send code | Enter code and Verify | Universal opens |
| Mobile OTP | Enter number and Send code | Enter code and Verify | Universal opens |
| Change method | Choose another method | Complete chosen method | Universal opens |

### Required states

Invalid identity, provider unavailable, provider cancel, provider failure,
duplicate identity, account link consent, code sent, wrong code, expired code,
resend countdown, rate limit, offline, retry and session restore. Providers not
approved for a build or geography are hidden, never left as dead buttons.

## `UNI-001` — Universal header controls

| Control | First tap | Second tap | Optional third tap / completion |
| --- | --- | --- | --- |
| Profile | Open account sheet | Choose account, language, area, workspaces or sign out | Selected screen opens or sign-out confirmation completes |
| Search | Enter query | Choose result or filter | Correct main/sub-action opens |
| Scan | Open scanner | Allow camera or choose image | Recognised result opens; denial has Settings/Cancel |
| Voice | Start listening | Allow microphone when needed | Recognised query populates Search; denial has Settings/Cancel |
| Notifications, when launched | Open inbox | Choose notification | Related order, booking, chat or task opens |

Search, Scan and Voice must never show generic “completed” messages in place of
results.

## `NAV-001` — Apple-inspired Mool navigation

### Required information architecture

- Floating bottom material with clear separation between Mool, the focused
  context and Chat.
- Mool expands into a spacious command palette for Social, Buy, Eat, Ride,
  Book, Pay and Work. It must not compress seven labels into an unreadable row.
- Selecting a main action dismisses the palette and opens that action's default
  useful sub-action.
- A dedicated, horizontally scrollable segmented control above content shows
  sub-actions for the selected main action.
- Chat remains a one-tap destination with unread count and a direct `Back to
  <previous action>` affordance.
- The active main action and sub-action are visually and semantically selected.
- The dock respects safe-area insets, keyboard visibility, text scaling and
  44-pixel targets.

### Required interaction states

Collapsed, Mool expanded, main action selected, sub-action selected, Chat,
keyboard open, compact device, large text, reduce motion and screen reader.

## Main and sub-action map

These labels are user-facing. They replace engineering terms such as “world” or
“mode”.

| Main action | Focused sub-actions | Default |
| --- | --- | --- |
| Social | Shorts, Videos, Feed, Create | Shorts |
| Buy | Grocery, Categories, Medicine, Basket | Grocery |
| Eat | Order Food, Book Table, Tiffin | Order Food |
| Ride | Bike, Auto, Cab | Bike |
| Book | Get It Done, Doctor, Salon | Get It Done |
| Pay | Recharge, Bills, Scan & Pay, Receipts | Recharge |
| Work | Earn Today, Delivery, Onboard, Verify, Workspace | Earn Today |
| Chat | People, Business, Orders, Support | People |

## `SOC-001` — Social intent paths

| Sub-action | First content tap | Second tap | Optional third tap / completion |
| --- | --- | --- | --- |
| Shorts | Open or swipe Short | Like, Comment, Share, Remix, Follow, Save or More | State changes, composer/share sheet opens, or chosen More action completes |
| Videos | Open video | Play, Comments, Share, Save, Follow, Channel or Mool action | Video plays or selected action completes |
| Feed | Open post | Like, Reply, Repost, Share, Save or profile | State changes or chosen composer/sheet/profile opens |
| Create | Choose Text, Photo, Poll, Thread or YouTube video | Create/edit content and attach one Mool action | Review and Post |

YouTube playback remains visibly YouTube-hosted. Mool actions such as Buy,
Book, Order, Apply, Visit or Chat remain separate and lead to complete
MoolSocial flows. No paid YouTube engagement is claimed.

## `BUY-001` — Consumer buying paths

| Sub-action | First tap | Second tap | Optional third tap / completion |
| --- | --- | --- | --- |
| Grocery | Choose product | Choose quantity and delivery | Add to basket |
| Categories | Choose category | Choose product | Add to basket |
| Medicine | Search/select medicine | Upload prescription when legally required and choose delivery | Add eligible item or request pharmacist review |
| Basket | Review basket | Choose address and delivery slot | Pay and place order |

### Buy clarity rules

- The consumer view shows retail quantities and home delivery.
- Counter pickup appears only after the user explicitly selects pickup and a
  store.
- Wholesale packs appear only in eligible business workspaces.
- Family basket is a repeat household basket, not a pricing tier.
- Campaigns and demand aggregation do not appear in the consumer product grid.
- Every item shows final price, quantity, availability, delivery promise,
  seller, cancellation/refund rule and the next action.

## `EAT-001` — Food paths

| Sub-action | First tap | Second tap | Optional third tap / completion |
| --- | --- | --- | --- |
| Order Food | Choose restaurant or dish | Add items and review basket | Choose address, pay and place order |
| Book Table | Choose restaurant | Choose date, time and guests | Confirm booking |
| Tiffin | Choose meal plan | Choose days, meals and address | Pay and start plan |

Empty restaurant results, closed kitchen, item unavailable, duplicate add,
cancel, payment failure and retry are required.

## `RIDE-001` — Ride paths

| Sub-action | First tap | Second tap | Optional third tap / completion |
| --- | --- | --- | --- |
| Bike / Auto / Cab | Set pickup and destination | Choose vehicle and review fare | Confirm ride |

Permission denial, manual location, no vehicle, fare change, driver cancel,
user cancel, retry, safety contact and payment failure are required.

## `BOOK-001` — Service booking paths

| Sub-action | First tap | Second tap | Optional third tap / completion |
| --- | --- | --- | --- |
| Get It Done | Choose defined task | Choose provider, scope and time | Pay/confirm task |
| Doctor | Choose doctor or specialty | Choose appointment slot | Pay/confirm appointment |
| Salon | Choose salon and service | Choose professional and slot | Pay/confirm appointment |

Each path shows scope, price, time, provider proof, cancellation terms, support
and completion confirmation before commitment.

## `PAY-001` — Payment paths

| Sub-action | First tap | Second tap | Optional third tap / completion |
| --- | --- | --- | --- |
| Recharge | Choose service/operator | Enter account/number and plan | Pay and open receipt |
| Bills | Choose biller | Fetch and confirm bill | Pay and open receipt |
| Scan & Pay | Scan verified code | Enter amount and confirm recipient | Authenticate and open receipt |
| Receipts | Choose receipt | View details | Share, download or get help |

Invalid code, unsupported biller, bill not found, duplicate payment protection,
pending payment, failure, retry, refund and receipt recovery are required.

## `WORK-001` — Work paths

| Sub-action | First tap | Second tap | Optional third tap / completion |
| --- | --- | --- | --- |
| Earn Today | Choose funded opportunity | Review eligibility, location, proof and payout | Apply |
| Delivery | Choose route | Review stops, proof and payout | Accept route |
| Onboard | Choose verified onboarding assignment | Review target and completion evidence | Apply |
| Verify | Choose funded verification task | Review evidence required and payout | Apply |
| Workspace | Choose workspace type | Enter business/professional details | Submit for verification |

No unfunded job, hidden payout rule or vague “opportunity” is allowed.

## `CHAT-001` — Chat paths

| Sub-action | First tap | Second tap | Optional third tap / completion |
| --- | --- | --- | --- |
| People | Choose conversation | Type, attach or record | Send |
| Business | Choose business conversation | Ask, attach or choose linked action | Send or open transaction |
| Orders | Choose order conversation | Choose order help topic | Send, cancel or open support |
| Support | Choose issue | Select affected transaction and explain | Submit case |

Chat always shows `Back to <previous action>` in addition to native back
navigation. Attachment, camera, microphone, offline send, retry, duplicate send
and permission-denied states are required.

## `COPY-001` — Production wording audit

### Audit procedure

1. Extract all visible strings from Flutter, Android, iOS and web surfaces.
2. Flag prohibited internal words from the design memory.
3. Flag passive, uncertain and trust-reducing phrases.
4. Replace each with a concrete user action or verified outcome.
5. Review empty, error, loading, permission and completion copy separately.
6. Add a CI check that prevents reintroduction of prohibited wording.

### Acceptance

- Every primary button begins with an unambiguous action verb.
- Every completed transaction says what completed and where the user can find
  it.
- Every failure explains what happened, what remains safe and what the user can
  do next.
- No fake success, dead action, internal implementation term or unsupported
  availability claim remains.

## `QA-001` — First live black-box audit

For each screen:

1. Start from the documented clean state.
2. Inventory every visible and reachable control.
3. Tap each control.
4. Tap every newly revealed control.
5. Continue until completion, cancellation or a documented external blocker.
6. Exercise success, invalid, empty, duplicate, cancelled, loading, retry,
   offline, permission-denied and failure states where applicable.
7. Record device, build, clean-state steps, exact taps, expected result, actual
   result, screenshot/video, logs and severity.

A screen remains open in the audit until every branch is accounted for.

## `FIX-001` — Defect lifecycle

Every defect must complete:

`Discover -> reproduce -> evidence -> ticket -> root cause -> fix -> rebuild ->
redeploy -> exact failed-tap replay -> affected journey -> full regression`

No ticket closes on code review or unit tests alone.

## `QA-002` — Independent full retest

Begin again from installation after all `QA-001` defects are closed. Do not
reuse prior state or evidence. Repeat the complete screenwise tap inventory,
affected-journey tests and full application regression on the supported Android
device set and iOS simulator/device set.

## Final release evidence

- screen-by-screen tap, sub-tap and nested-tap coverage;
- passed, failed, fixed and blocked paths;
- ticket and evidence for every defect;
- exact failed-tap replay results;
- every affected-journey rerun;
- final full-regression results;
- remaining real-device or external blockers;
- evidence-based **GO** or **NO-GO** recommendation.
