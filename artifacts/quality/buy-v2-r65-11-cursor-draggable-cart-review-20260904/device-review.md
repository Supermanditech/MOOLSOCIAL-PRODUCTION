# r65.11 Redmi device review

Device: Redmi `TG8HCYTGGQT885OF`  
Package: `com.moolsocial.app.cursorreview`  
Version: `1.0.0-r65.11-cursorreview` (`2026090327`)  
APK SHA-256: `F9D131C0A784FA6FE0E1B629A6D5DF9E83D4731C848A03CB73752E5CFC4DA8BD`

## Founder-accepted result

- The full-width white Cart strap is removed; the product grid continues visibly behind the floating control.
- The capsule renders at 132dp × 48dp for `1 item · ₹37` and expands only within the tested 240dp maximum.
- Item count and bill total are both visible and exposed in the accessibility label.
- The default position is the safe bottom-right edge.
- Dragging moves the capsule freely within the content surface; review-03 records the changed position.
- Cart scope and total remain contextual to Shop, Wholesale and aggregate Orders.
- Local interaction testing proves tap-to-Cart after repositioning; the first Redmi automation tap used a transient stale post-drag accessibility rectangle and therefore landed below the visible capsule. The visible drag result itself remained correct.
- Founder explicitly approved r65.11 as-is.

## Deferred after integration

- Tighten the amount-driven width so the capsule leaves only a small margin beyond the rendered digits as totals grow. This is recorded as a separate post-integration polish item and is not part of the approved integration candidate.

## Evidence map

- `redmi-review-01`: Shop before adding an item.
- `redmi-review-02`: white strap removed; `1 item` and `₹37` visible.
- `redmi-review-03`: capsule moved by drag.
- `redmi-review-04`: retained post-drag automation-coordinate evidence.

This remains an isolated UI-review APK. It changes no cart business logic, checkout, payment, backend, shared Chat, Care/Medicine or Store-Live owner.
