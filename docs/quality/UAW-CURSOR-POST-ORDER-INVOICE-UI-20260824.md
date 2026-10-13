# UAW-CURSOR-POST-ORDER-INVOICE-UI-20260824

Founder date: 24 August 2026 IST  
Lane: `cursor_ui`  
Branch: `work/cursor-ui/buy-screen-subactions-ui-20260823`

## Founder direction

After the Buy header-removal and account-access ticket, implement the next
atomic Buy UI/UX outcome for a customer who places a Shop or Wholesale order.
The customer must see what was placed, be able to open an order invoice inside
the mobile app, reach the same invoice from Orders, and have an invoice-download
action ready for the consolidated runtime.

The OPPO installed-runtime baseline and no-regression rules recorded in
`UAW-CURSOR-BUY-SCREEN-SUBACTIONS-UI-20260823.md` remain mandatory. This ticket
does not authorize authentication, backend, Android/iOS configuration,
dependencies, signing, Firebase or release-owner changes.

## Interaction contract

- Successful checkout opens one post-order page headed `Order placed`.
- The page preserves and renders the exact immutable product, quantity and line
  total snapshot for each Shop or Wholesale fulfilment order.
- Every placed-order card exposes 44-pixel `View invoice` and `Track order`
  actions.
- `View invoice` opens a full-screen in-app order invoice. System Back and the
  visible Back action return to the exact prior Confirmation, Orders or
  Tracking surface.
- Orders cards expose a direct Invoice action; Tracking exposes a full-width
  View invoice action.
- The in-app invoice renders the truthful order ID, type, seller, payment
  method when recorded, exact placed lines when available, amount, delivery
  details and download action.
- Invoice download is an injected runtime outcome contract. The UI announces
  success only after the handler returns `saved`; a missing handler reports
  that download is not yet available while preserving in-app viewing; failures
  provide retry copy. No simulated file-success message is permitted.

## Mandatory gates

- Shop and Wholesale quantities survive cart clearing after confirmation.
- Confirmation, Orders and Tracking all reach the same full-screen invoice and
  preserve their return state.
- The invoice contains no persistent MoolSocial destination rail.
- Primary actions remain at least 44 logical pixels.
- The invoice fits 320 x 568 at 140% text without exception, clipped primary
  action or prohibited machine copy.
- Focused Buy, navigation-motion and session coverage tests pass before commit.
- Review captures show the 360 x 800 post-order and invoice states.

## Integration boundary

This Cursor commit supplies the complete native Flutter UI, navigation and
download-outcome seam. A production storage or server invoice implementation
must be connected by the authorized consolidated runtime owner. Until then,
the default runtime remains honest: customers can view the invoice in-app and
are not told that a file was saved.

## Cursor implementation evidence — 24 August 2026 IST

- Touched-source `dart analyze`: pass, no issues.
- `buy_v2_session_test.dart` plus `buy_v2_session_coverage_test.dart`: pass,
  `38/38` tests.
- `buy_v2_screen_test.dart`: pass, `66/66` tests.
- `buy_v2_navigation_motion_test.dart`: pass, `8/8` tests.
- Explicit `post-order confirmation and invoice review captures`: pass.
- Confirmation capture SHA-256:
  `AC55EBD648FC05F7B47524C21ED871BD4C58F390ADC5189CB626A8938CA1A9C1`
- In-app invoice capture SHA-256:
  `28AC07354F6FD345CCA5E60BC16B0B6FED5D433A048E94EB9A573557E19A5000`
- No APK was built or installed; the parallel OPPO production package was not
  changed.
