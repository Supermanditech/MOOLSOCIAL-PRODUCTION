# STORE-VISUAL-MASTER-001 — Founder visual and interaction preferences

Canonical implementation guide, consolidated 22 September 2026. This extends
the existing master ticket; it is not a new ticket, design system or approval.
Read this before designing, editing, testing or presenting every authorized
Store/Counter Sale screen. For future authorized screens elsewhere, apply the
general preferences only where their specific accepted design permits it.

## Authority, coverage and conflict handling

- Sources: founder messages supplied in the current conversation for the recent
  ten-day work period, the existing master, screenwise OPPO defect records,
  subsequent local review records and the latest Stock v24 approval. This is a
  consolidation of accessible evidence, not a claim to have read unavailable
  messages from every account or verified their individual calendar dates.
- **Explicit** below means stated/approved by the founder. **Inference** means a
  design default derived from repeated feedback; never treat it as permission
  to override a specific approval, required information or functional safeguard.
- Current screen-specific founder decisions supersede older preferences for
  that same scope. Preserve the old decision as history, clearly superseded.
- Existing brand tokens, accepted references, accessibility, privacy, financial
  accuracy, draft protection and repository/owner/release boundaries remain in
  force. This guide supplements them; it does not modify their authority.
- No global rewrite, Cursor merge, dependency, backend, payment, publication,
  message, APK or Git operation is authorized merely by this document.
- If a genuine conflict cannot be solved within the approved scope, identify
  the exact conflict and seek the smallest decision. Do not silently weaken a
  safeguard or invent a second competing rule. Prefer reuse over a new system.
- Visual approval covers the shown state/layout, not automatic field-mapping,
  production-data, backend, OPPO or all-ticket acceptance. Technical correctness
  and discovery of internal defects remain the implementing agent's job.

## The founder's visual preference, in one paragraph

**Inference, strongly supported:** premium means calm, compact, useful and
intentional. A retailer should see products, amounts and actionable information
immediately, with familiar controls and minimal navigation. Richness comes from
alignment, typography, good imagery, clear states and consistent brand treatment;
not tall headers, large empty cards, repeated icons, more gradients or more pages.
Use the latest approved Buy styling as a reference when requested, adapted to the
retailer's task. Do not make the founder repeatedly discover obvious problems.

## 1. Reuse and eliminate duplication — explicit

- One business intent, one state/data owner and one shared implementation. Never
  build catalogue, manual entry and CSV as three independent product journeys.
- Audit every visible icon, label, menu entry, route and primary action before
  adding it. Record what it does, where the existing entry is and why another
  entry is necessary. An existing shortcut on another screen is not, by itself,
  permission to repeat it: the founder explicitly removed Stock + despite that
  convenience argument. Default to the agreed canonical entry.
- Remove duplicate searches/scanners, toolbars, counts, identity summaries,
  More menus and duplicate download locations. Remove the empty container too;
  hiding the icon while retaining its width/height is not a completed fix.
- Do not confuse distinct intents: Add products records held inventory; Buy
  stock purchases replenishment. Category groups products; stock filters narrow
  availability/status/brand. Shortlist is not inventory and neither is a cart.
- Reuse shared product editor, schema, validation, thumbnail and saved inventory
  across catalogue/manual/CSV. Counter Sale selects the same saved Store stock.
- Apply shared fixes once. Regression-test blank/manual and imported inputs
  without presenting the same editor as a new independently designed screen.

## 2. Layout, density and typography — explicit plus bounded inference

- Content first: SKU rows, values and real task information should start near
  search/header. Cut ornamental or redundant full-width strips and repeated titles.
- No separate whole page for a short unavailable message, tiny form or repeated
  facts when the originating screen can host it safely. Conversely, use the
  approved full-screen picker/editor where the task needs room; not everything
  should be compressed into a popup.
- Compact does not mean tiny text or unsafe hit targets. Preserve existing
  accessible target requirements (normally 48dp Android, never below applicable
  44dp minimum), contrast, labels and text scaling. Shrink decoration before text.
- Use aligned columns/baselines and restrained type weights. No scattered labels,
  gratuitous line breaks, clipped prices, repeated headings or all-bold text.
- Make short facts/numbers share rows where sensible. Names/descriptions and
  legitimate long values get the width they need. Numeric fields must accept
  large amounts, including 1 crore where supported, without allocating a full
  empty lane for a small value or shifting unpredictably on every keystroke.
- Collapse/expand shared editor sections, including the first section. Keep
  labels, units and concise entry guidance close to fields. Do not hide validation
  errors in collapsed sections without an indicator and a route to the field.
- Empty space is acceptable when data is genuinely sparse. **Inference:** do not
  fill it with invented cards/content; remove oversized wrappers and keep the
  useful information together. A sparse state must still have a clear next step.

## 3. Navigation and placement — explicit, newest decisions first

- Bottom Store/Orders/Sales/Stock navigation switches sections. It does not
  universally replace Back for editors, selected records, search/alert origins,
  checkout or interrupted work. Preserve state restoration and discard protection.
- Stock v24: no visible Back at ordinary Stock root; reclaim its space for Store
  name. Retain Back for nested/direct-filter/search/alert return contexts.
- Shared contextual rails have predictable positions, not empty-space seeking.
  Scroll vertically at the right when width permits; on narrow/enlarged-text
  phones use a horizontal action row above bottom navigation. Never cover values,
  reserve an empty coloured full-height strip or relocate during typing/scrolling.
- Current tested Store thresholds: below360dp, or above1.3 text scale below600dp,
  uses54dp horizontal actions. These are this implementation's tested values,
  not universal immutable breakpoints for every app or device.
- When an inline message and fixed summaries leave little working space at
  enlarged text, let that upper content scroll; keep navigation accessible.
  A passing overflow test is not evidence that the page is usable. This technical
  application of the compact-layout preference is not a new founder approval.
- Keep action order, semantics and truthful selected state consistent in either
  orientation. No action rail on settings forms where it has no purpose.
- Catalogue is the default Add Product mode. A clear title/dropdown switches
  catalogue/manual/CSV in the same screen area. No permanent three-tab/title stack
  crowding search; no arrows drawn between the alternative journeys.
- A vague icon-only More menu is not discoverability. Essential actions must have
  visible intent/labels in their designated location. Use familiar semantic icons
  with accessible names; do not invent another logo or module-specific palette.
- Latest Share amendment: do not keep a hard-coded public-link prerequisite
  banner or its empty strip. Publication/link status must come from the actual
  Store-scoped response, not a go-live switch or local visibility setting. Until
  that adapter exists, Share is disabled with accessible unavailable semantics;
  never simulate successful sharing. This supersedes the v27 banner approval.

## 4. Search, categories, filters and scanner — explicit

- One natural, unboxed inline search for the current context. It gets usable
  width immediately; no duplicate global search above it and no decorative box.
- Retailer-facing hints, relevant suggestions/history and matching results.
  Search text/keyboard/filter state must survive expected edit/return journeys.
- Stock v24: isolated category icon in search row; table directly underneath.
  No Stock heading/count/+ /Filter strip and no separate swipe-hint text row.
  Horizontal table scrollbar remains. Low/out/public/private/brand filters are
  available inside the full-screen Stock category window.
- Use the current requested Buy category reference, not an older screenshot.
  Stock picker shows saved-stock category IDs/counts, not a buyer cart or all
  public catalogue inventory. Full-screen, unboxed search, compact image tiles,
  obvious selection/clear/close and readable enlarged-text layout.
- Catalogue saves need real tile-level save actions and a working shortlist
  filter. Saved candidates remain editable before Save to Store.
- Camera and connected hardware scanner feed exact SKU/pack matching and review.
  Manual code entry is only a explained recovery: e.g. "Can't scan? Enter barcode."
  Never silently add an unknown/ambiguous scan or describe typed codes as scanning.

## 5. Products, thumbnails and stock — explicit

- MoolSocial catalogue: compact SKU tiles, list/grid options where approved,
  exact variant/pack identity, tap to add/review and optional shortlist.
- Store stock: compact bank-statement-style table/list with small square
  thumbnails, aligned prices/quantities, horizontal scrolling and stable identity.
  No tall grid cards. Counter Sale Add Items: compact thumb/name/pack/price/stock
  and+/−; not the entire stock-statement column set. Keep bill total/action reachable.
- Store thumbnails should match the latest approved Buy image treatment at a
  smaller square size. Fill the image area effectively without growing the tile,
  extra nested boxes, distortion or cutting off identifying pack information.
  No blanket BoxFit.cover rule: choose fit per actual asset and approved reference.
- Preserve full-quality exact SKU/variant/pack media references; small thumbnails
  do not become the public photo source. Production catalogue photos belong to
  MoolSocial. Test images/placeholders are not verified production media.
- Saved SKU remains editable; Save to Store for new, Save changes for existing.
  Publish is distinct from saving stock. Do not create pretend public previews.
- Keep daily stock facts in stock; sold units belong in Sales, not a repeated
  Sold today column. Do not put expiry alerts in this Stock surface. Reports can
  carry fuller metadata without forcing it into every daily row.

## 6. Forms, settings and information ownership — explicit

- Product-specific facts are editable in the shared product editor; catalogue
  facts prefill, applicable CSV columns import. Do not force re-entry perSKU.
- One-time Store identity/address/contact/business details and applicable
  payment/return/fulfilment defaults belong in existing Store Settings.
- Public Buy/Wholesale fields require an authoritative provider/catalogue/
  Store/batch/order/system source and validation. Visual approval does not
  approve incomplete mapping, remove required data or make publication safe.
- Manufacturer/packer/importer may need long names; net quantity/country and
  other short fields can share rows. Use Purchase price, not Purchase cost.
  Remove verbose "How do you track product"/redundant availability headings;
  retain the actual tracking capability with concise guidance where required.
- Binary preferences use clear On/Off switches (e.g. auto-send); do not convert
  a genuinely three-state or multiple-choice business rule into a false binary.
- Customer visibility must clearly mean public listing, not local inventory.
  Compact labelling must distinguish save, publish, availability and approval.
- One Store workspace supports business type and independent Retail/Wholesale
  selling capabilities. Do not infer wholesale from pack size or price alone.
- MoolSocial/fleet owns delivery radius/coverage and delivery charges, not editable
  retailer amounts. Retailer readiness/channel preferences are distinct.
- Public payment terms and customer-specific eligibility are distinct from
  payment gateway brands or private settlement details. Avoid irrelevant public
  payment-mode controls. No fabricated eligibility or confirmation.
- Unlimited/custom active-order capacity must not be arbitrarily capped at20.
- Remove redundant standalone customer preview/business-info screens; required
  facts stay in settings/editor and are validated before actual publication.

## 7. CSV and large-data review — explicit

- Support frontend review up to10,000 SKUs using bounded/lazy lists, search,
  selection and bulk actions. Host fixtures are not backend/device qualification.
- Every issue row identifies product, CSV row, error type and corrective action.
  Prefer "Missing price", "Invalid quantity", "Already in Store" or "Repeated
  in this file" over a wall of technical fields. Preserve raw inputs and evidence.
- All-invalid files open Needs attention, not a blank Ready tab. Correct through
  the shared editor/schema where supported; revalidate before becoming ready.
- Avoid repeated instructions and bulky rows. Keep field keys/details accessible
  secondarily. Show selected versus ready versus rejected counts truthfully.
- Per-product retailer CSV values map to public fields; inherited Store/system
  facts stay out of mandatory per-row entry. Each variant/pack retains own identity,
  photo, price and stock. Missing information must not silently become publish-ready.

## 8. Downloads, invoices and payment results — explicit

- **Latest:** central Reports & Downloads owns downloads; do not restore repeated
  Stock or perSKU export actions. Customer: Profile/Downloads; business: selected
  Store workspace. Reuse one feature with correct account/business boundaries.
- In the centre, choose the applicable period then tap PDF/Excel/CSV directly.
  No app confirmation/format-selection popup. Respect unavoidable platform rules;
  never promise silent native saving before proving it.
- Historical periods need genuine records. Today's snapshot is not a historical
  ledger, audit certificate or finance-application guarantee. Distinguish unavailable
  historical data from empty results; never fabricate balances/transactions.
- Invoice layouts follow the founder's three PDF references recorded in
  STORE-INVOICE-FORMAT-REFERENCES-20260922.md. Use applicable document types and
  payer/payee ownership, not one misleading generic invoice for every relationship.
- Sending/sharing outcomes should state who/where only after success. Keep invoice
  history; do not create an empty full screen for an amount or offer redundant save
  prompts. Do not send messages or record payments simply to demonstrate a design.
- Customer statements/outstanding summaries belong in the report centre; proper
  source records and institution-specific requirements remain separate dependencies.

## 9. Theme, colour, gradients and motion — explicit plus inference

- Reuse canonical white/navy with restrained saffron/green accents. One dominant
  primary treatment, clear selected/focus/disabled states, semantic errors paired
  with words/icons. No colour clutter or module-specific replacement branding.
- Gradients are optional, subtle and tonal on a suitable focal surface. A request
  for premium colouring is not a requirement to gradient every label/background.
  Prefer readable solid financial/table text; avoid rainbow/body-text gradients,
  oversized shadows, nested cards and glossy decoration.
- Match existing type/icon/radius/spacing tokens; do not invent new values per
  screen without need. Different contexts may have appropriate density, not a
  different visual identity. Review selected, disabled and error states too.
- **Inference:** motion should explain navigation/state and remain quiet, stable
  and compatible with reduced motion. It must not reflow actions, delay task access
  or conceal missing data. Existing accepted motion contracts remain authoritative.

## 10. Superseded decisions — prevent recurrence

| Older approach | Current decision |
| --- | --- |
| Add Product heading plus permanent catalogue/manual/CSV tabs | Catalogue-first, compact in-place mode selector |
| Stock grid/list choice | Stock statement table; catalogue can retain list/grid |
| Stock + retained as useful shortcut | Removed; use Store-home Add products |
| Stock category/count/filter toolbar below search | Entire strip removed; isolated category in search |
| Visible Current/Today/week/month and exports on Stock | Central Reports & Downloads |
| Separate swipe instruction lane | Remove lane; retain table scrollbar |
| Always show Back on Stock | No ordinary-root arrow; nested return remains |
| Always-right rail or rail seeks vacant space | Predictable width/text-scale responsive placement |
| Customer-preview/read-only repeated Store pages | No redundant preview; validate real public mapping |
| Public payment brands/modes | Relevant payment terms and eligibility |
| Visual approval means complete | Only the reviewed visual state; technical/backend/device gates separate |
| Share v27 hard-coded unavailable banner | Removed by later founder amendment; link-driven capability, no fixed strip |

Create Offers remains **ON HOLD** until offer types, fields, calculations,
eligibility, terms and actual public Buy/Wholesale/checkout mapping are agreed.
General approval, this guide and a next-screen instruction do not lift that hold.

## Before every screen: implement, inspect, then ask for approval

1. Read this guide, the latest specific screen decisions and the actual current
   source/reference. Record the source version when using Cursor work read-only.
2. Name the screen's one purpose and data owner. Inventory existing paths/actions;
   choose what to reuse, remove, relocate or retain and give a practical reason.
3. Map required fields, defaults, ownership and failure states. No cosmetic fix
   that drops information or turns an unavailable service into a false success.
4. Build only the authorized next screen/shared component, preserving approved
   neighbors. Do not build the entire future journey before architecture approval.
5. Run local connected checks: taps, focus/keyboard, selection, Back/cancel,
   scroll, save/retry, account/Store changes and relevant errors. Preserve counts,
   prices and inventory correctness when changing layout.
6. Render actual app states: normal and narrow, enlarged text, sparse and loaded,
   long names/large values, keyboard open/closed and applicable errors. Inspect
   every image top-to-bottom BEFORE the founder sees it. Do not use image mockups
   as implementation evidence or let green tests substitute for visual inspection.
7. Reject your own result if it contains duplicate controls/paths, unused strips,
   blank standalone pages, boxed requested-inline search, clipped values, wrong
   image fit, wasted field width, squeezed content, poor error copy or fake states.
8. Present affected screens in the bounded batch with concise evidence/limits;
   wait for founder approval. Capture new feedback once under existing ticket IDs,
   reconcile duplicates and update this guide only for reusable decisions.
9. Approved renders are not authorization to commit/push/build. Follow the actual
   requested Git/device sequence. Do not advance/claim all58 complete while known
   frontend or evidence work remains. Backend and10k device tests stay deferred.

## Evidence and latest approval

Original counting stays58 grouped items (57 existing plus this master), not58
new bugs/screens. Preserve all existing AP/CS IDs and child grouping.

- Share Store v27 was visually approved, then the founder explicitly removed its
  static sharing-prerequisite line. Preserve the rest of the approved screen.
  Link capability still needs authoritative publication/link integration.
- Founder also approved Stock v24 after reviewing removal
  of its strip/root Back and its full-screen category link.37 local checks passed;
  OPPO and Git checkpoint remain separate. No approval of every other screen inferred.
- Retained task evidence: ACTIVE-WORK-RECORD.md; outputs/store-r66-37-screenwise-
  defect-review.md; counter-sale-oppo-defect-tickets.md; STORE-CONTEXT-RAIL-V7-
  FORENSIC-AUDIT.md; STORE-BATCH2B-PHOTO-FIT-COMPARISON.md; STOCK-V24-REVIEW.md.
- Source-specific provider/public/PDF contracts remain their existing owners;
  this document gives placement and UX principles, not a second data schema.
- Canonical location is this repository file. The original task-local visual
  master is a pointer plus retained historical evidence, not a competing standard.
