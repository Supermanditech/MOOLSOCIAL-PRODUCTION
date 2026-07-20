# MoolSocial product design memory

Status: **mandatory for the complete application**

Last confirmed by the product owner: 20 July 2026

## Open launch-blocking conformance issue

On 20 July 2026, the product owner reported a material regression between the
approved HTML prototype and the current physical-phone build. The reported
scope is application-wide and includes:

- visual hierarchy, styling, spacing and component treatment;
- main action and sub-action wording;
- tap, sub-tap and nested-tap structure;
- the screens or visible results that complete each user intent.

This issue is tracked as `UI-CONFORMANCE-001` in
[`QA-024-APPROVED-PROTOTYPE-CONFORMANCE.md`](../quality/QA-024-APPROVED-PROTOTYPE-CONFORMANCE.md).
It blocks founder design approval and any production-launch claim until the
screenwise comparisons and acceptance replays are complete.

The existing automated tests and 81 Flutter goldens prove consistency with the
current implementation. They do **not** prove conformance to the approved
prototype and must not be used as the sole design-approval oracle.

All remediation work must be isolated from `main` until accepted. The working
branch is `remediation/prototype-conformance-2026-07-20`. Screen-specific
observations supplied by the product owner are appended to the QA-024 issue
register before code is changed.

The accepted implementation strategy is the parallel native Flutter UI V2
rebuild in
[`ADR-0002-PARALLEL-UI-V2-CONFORMANCE-REBUILD.md`](../decisions/ADR-0002-PARALLEL-UI-V2-CONFORMANCE-REBUILD.md).
Approved HTML is finalized and frozen screenwise before V2 implementation;
existing tested non-UI application layers are reused.

## Permanent product rule

Every MoolSocial user-facing surface must use one coherent, Apple-inspired
interaction and visual system. This applies to Android, iOS, the marketing
website, creator and business upload tools, workspaces, admin tools, dialogs,
empty states, permission states and future journeys.

Apple-inspired means:

- calm hierarchy with one obvious primary intent;
- content-first layouts with generous, consistent spacing;
- high-quality typography and restrained use of colour;
- translucent or elevated navigation only where it improves orientation;
- direct manipulation, immediate feedback and reversible actions;
- predictable back, close, cancel, retry and completion behaviour;
- smooth, short motion that explains state changes;
- minimum 44 x 44 logical-pixel tap targets;
- native platform conventions for keyboards, permissions, sharing and account
  approval;
- accessible contrast, text scaling and screen-reader labels.

It does **not** mean copying Apple trademarks, proprietary artwork or an exact
Apple application. MoolSocial keeps its own identity:

- navy `#000080`;
- saffron `#FF9933`;
- green `#138808`;
- the approved MoolSocial wordmark and tricolour identity line;
- Mool as the universal action launcher;
- outcome-led socio-commerce language and flows.

## Interaction architecture

Every reachable control must satisfy this contract:

1. **First tap — choose intent.** The user selects a main action or a clearly
   named object.
2. **Second tap — make the decision.** The user chooses the relevant subtype,
   item, provider, slot or method.
3. **Third tap — complete or commit.** When needed, the user confirms, pays,
   posts, books, sends, applies or saves.

A flow may complete in fewer taps when the tap itself produces the intended
result. Extra taps must not be invented merely to satisfy the three-depth model.

Every tap must do at least one of the following:

- visibly change the current state;
- reveal the next decision;
- open a complete screen or platform-controlled surface;
- complete the intent and show a durable result.

Snackbars and toasts may confirm small reversible actions such as Save. They
must not replace a required screen for buying, booking, posting, paying,
applying, authentication or support.

## Navigation rules

- The Universal screen opens in Social.
- Mool opens the seven main actions: Social, Buy, Eat, Ride, Book, Pay and
  Work.
- Chat remains reachable in one tap and always provides a direct return to the
  previously focused main action.
- The bottom navigation uses one Apple-inspired floating material treatment
  across the app.
- Main actions and focused sub-actions must not compete in one cramped row.
- Main actions appear in the Mool launcher. The focused action's sub-actions
  appear in a separate, readable control immediately above the content.
- Back returns one navigation level. Close dismisses only the current overlay.
  Cancel preserves the prior safe state.
- The current main action and current sub-action are always visually apparent.
- Product verticals use `MoolOutcomeDock`: Mool and Chat remain stable edge
  actions while no more than three readable current-task actions occupy the
  separate middle rail.
- Standard product content uses `MoolCardSurface` so elevation, border,
  pressed feedback and reduced-motion behavior remain consistent.

## Production language rules

Visible copy must describe what the user can do or what has happened.

Preferred verbs include:

`Choose`, `Watch`, `Post`, `Buy`, `Add to basket`, `Order`, `Book`, `Pay`,
`Send`, `Apply`, `Accept`, `Upload proof`, `Save`, `Try again`, `Change`,
`Cancel`, `Finish`.

The following engineering or prototype terms are prohibited in user-facing
copy unless the user is explicitly in a developer/admin diagnostic tool:

`bootstrap`, `registry`, `route`, `endpoint`, `payload`, `mode`, `world`,
`handoff`, `state machine`, `mock`, `placeholder`, `internal`, `test action`,
`intent result`, `screen 01`, `screen 02`, `screen 03`, `screen 04`.

Operational conditions must be written as confident, decision-ready facts.
For example:

- Use `Delivered by 7:30 pm` instead of `Retailer will confirm stock`.
- Use `Available for home delivery` instead of `Fulfilment mode enabled`.
- Use `Your order is confirmed` instead of `Order state changed`.
- Use `Upload delivery photo` instead of `Submit proof payload`.

Unavailable actions are either hidden when they are not launched or shown with
an honest reason and a useful next action. Dead controls are never allowed.

## Completion evidence

A screen or journey is not production-ready until it has:

- a tap inventory;
- first-, second- and optional third-tap acceptance tests;
- success, invalid, empty, duplicate, cancelled, loading, retry, offline,
  permission-denied and failure coverage where relevant;
- clean-state exact failure replays;
- affected-journey regression;
- complete application regression;
- Android and iOS visual checks at supported sizes;
- no prohibited internal wording in user-facing surfaces.

This file is the durable project memory. New tickets, code reviews and release
gates must cite it.
