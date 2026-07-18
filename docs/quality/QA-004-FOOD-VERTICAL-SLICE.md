# QA-004 — Food production vertical slice

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 26–29
- Food entry, restaurant selection and search
- Delivery, pickup, table-QR and scheduled fulfilment
- Menu filtering, availability, customization, basket and payment
- Order tracking, cancellation, support, bill and meal rating
- Table inventory, party size, time, table package, confirmation and
  cancellation
- Tiffin kitchen, food style, menu, meal, slot, plan, address, skip, pause and
  renewal cancellation

## Dedicated black-box coverage

- Scenarios: 10
- Passed after exact defect replays: 10/10
- Covered outcomes: successful, empty, invalid, duplicate, unavailable,
  cancelled, loading, failed payment, failed booking, failed subscription,
  retry, provider closed/paused, compact phone and cross-journey state.

## Defects discovered and exact failed-tap replays

| Defect | Root cause | Fix | Exact replay |
|---|---|---|---|
| Invalid voice, QR, schedule or address input could appear to do nothing | The error was written to the page banner behind an open bottom sheet | Added inline validation to the active sheet before any state mutation | Open each sheet → submit empty/short input → correction appears beside the field → correct input → intended next state opens: passed |
| Dismissing a voice/QR sheet could throw during its closing animation | The local text controller was disposed while the overlay was still animating | Delay controller disposal until the route transition releases the sheet | Voice search → valid query → close → rebuild results; Table QR → valid code → open menu: passed |
| Menu item actions overflowed after a duplicate add | Both natural-width actions competed inside one unconstrained row | Constrained the details action with `Expanded` and preserved the finite quantity control | Add Veg thali → quantity control replaces Add → no overflow at 360 px or 412 px: passed |
| Home context tiles and tiffin kitchen cards clipped by a few pixels | Fixed rail height did not include real font metrics and padding | Tightened context typography/padding and increased the kitchen rail height | Eat home and Tiffin on 412 × 915 and compact 360 × 800: passed |
| Food success text leaked into Table and Tiffin | One shared Eat session retained the previous route's notice | Clear transient messages before each Eat dock navigation | Order → Add Veg thali → Basket → Table → Tiffin: no stale banner on either destination: passed on automation and OPPO |

## Affected-journey rerun

- Food dedicated suite after initial fixes: 9/9 passed.
- Universal entry plus Food suite: 23/23 passed.
- Cross-journey state-leak regression added after device discovery.
- Food dedicated suite after device fix: 10/10 passed.
- Analyzer after all fixes: no issues.

## Full regression

- Full application cycle 1: 63/63 passed.
- Full application cycle 2: 63/63 passed.
- Final full application regression after physical-device state-leak fix:
  64/64 passed.
- Android debug APK built successfully for `com.moolsocial.app` with
  `MOOLSOCIAL_EMULATOR_HOST=192.168.31.66`.
- Non-blocking build warning: several current plugins still apply the Kotlin
  Gradle Plugin directly and must be upgraded before a future Flutter version
  removes that compatibility.

## Physical OPPO replay

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Preserved authenticated setup → Universal Social: passed.
- Universal → Mool → Eat → Order Food → production order route: passed.
- Menu → Veg thali → Add → visible success → View basket → price and delivery
  review: passed.
- Basket → Table: production table inventory and booking controls visible.
- Table → Tiffin: production kitchen, food style, meal and plan controls
  visible.
- Device-discovered stale notice was fixed, rebuilt and reinstalled.
- Exact replay Order → Add → Basket → Table → Tiffin shows no previous-route
  notice: passed.
- Evidence:
  - `artifacts/device/moolsocial-production-food-device.png`
  - `artifacts/device/moolsocial-production-food-basket-device.png`
  - `artifacts/device/moolsocial-production-table-replay-fixed.png`
  - `artifacts/device/moolsocial-production-tiffin-replay-fixed.png`

## Current gate

The Food vertical slice is GO for continued production implementation against
the deterministic gateway interfaces. Live payment, restaurant inventory,
delivery, table and tiffin provider certification remain later external
integration gates; the UI does not claim those external confirmations today.
