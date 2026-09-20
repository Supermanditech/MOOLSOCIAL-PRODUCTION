# UAW-ADD-PRODUCT-SCREEN1-20260920

Status: OPEN. Screen 1 implementation/local review only; no founder visual or
physical OPPO acceptance yet. Actor: authorised Retailer/Grocery Store operator.

## Founder authority and isolation

Founder approved Screen 1 registration/isolation and explicitly approved starting
from remotely verified `a425fd89445a4650533b14903d99215cfed74034` when v88 was
confirmed absent. This is a ticket-specific work checkpoint, not accepted runtime.
Do not create/move v88, alter central baseline, or falsely close Counter Sale.
Counter Sale CS-OPPO-015 is committed/pushed and remains physically unverified.
Its original checkout stays untouched; there is no concurrent Counter Sale work.

Standing authority covers only narrow, necessary blockers for this approved
ticket. No broad governance changes, new modules/backend scope, paid services,
destructive operations, production actions, APK/install or automatic acceptance.
Implement/test one screen, present the actual render, then wait for founder
approval before downstream work. Routine covered prerequisites need no repeated
permission request. Preserve source, evidence and all existing checks.

## Outcome and minimum complete scope

Classification: mvp_supporting / launch-supporting. Store inventory entry supports
the approved Buy-to-Retailer/Grocery commerce launch. Opening Add product presents
three understandable options, including when the Store has no products:

- Find in MoolSocial catalogue: existing search/scan picker.
- Add manually: existing blank product and shared editor.
- Import CSV: existing importer, not another product system.

The title is Add product. Never label this First product. Back/cancel returns
without creating inventory. Keep Store identity stable across async navigation.

## Reuse and exact owners

- `apps/mobile/lib/features/work/screens/store_add_product_sheet.dart`: entry
  presentation alongside existing picker; no additional state/service owner.
- `apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart`:
  existing `_addProducts`, `_blankProduct`, `_edit`, `_importCatalogue` wiring.
- `apps/mobile/test/work_workspace_layout_safety_test.dart`: affected entry route.
  Reuse this existing test owner for focused entry actions, responsive layout
  and retained local renders rather than adding another harness.

Existing `work_models.dart`, WorkSession inventory/persistence, scanner and CSV
handler are reused, not rewritten. New entry presentation is necessary because
the old picker immediately mixes search and products and does not expose all
three approved entry choices. No new backend, route registry or dependencies.

## Standing journey architecture — remains open beyond Screen 1

Three inputs, ONE product implementation: catalogue/search/scan prefills the
Store record; manual starts blank; CSV populates multiple records. Share model,
editor, validation, inventory, save/update and publication rules. Only input
handling differs. Do not code three independent systems.

Later approved catalogue blocks must support tap-to-add and selective editing
without compulsory review; existing Store products edit instead of duplicating.
One-time Store/payment/delivery setup stays in Store Settings. Never mutate a
global master product from a Store edit. Do not invent prices, stock, approved
photos or cloud publication. Added and publicly published are different states.
Current catalogue fixtures are not proof of a live shared catalogue or 5,000-SKU
scale. CSV matching/quoted fields/errors/retry and downstream editor shortcomings
remain separate later journey work; exposing entry buttons does not solve them.

## Tests and approval boundary

Test entry actions/cancellation, existing picker/manual/CSV dispatch, zero-product
Store, Store-switch guard, 320/360/412 widths, enlarged text and landscape.
Inspect actual Flutter local renders, not imagined mockups. No OPPO/APK claim.
Show ONLY Screen 1 for founder approval; later screens require separate approval.
Full journey remains open until all three paths have connected local tests,
founder-approved screens and physical OPPO testing with defects dispositioned.

## Scope guard

Apply the founder's supplied scope-guard image: smallest sufficient change,
reuse first, relevant call paths only, no speculative abstractions or unrelated
refactors/dependencies. Preserve validation/security/accessibility. Run relevant
checks and don't repeat passing tests absent changed inputs or required gates.
Report actual evidence/gaps; do not substitute planning for implementation.

## Exclusions and dependencies

No catalogue-block/editor/import redesign before Screen 1 approval. No shared
catalogue backend, media pipeline, payment, Store setup, Counter Sale redesign,
APK, live messages/payments, production release or acceptance tag. The exact
checkpoint admission does not approve a missing central baseline.
