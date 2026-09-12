# r65.6 candidate contract

Candidate: `UAW-BUY-V2-R65.6-CURSOR-SCANNER-A11Y-FIX-20260904`

This successor preserves every approved r65.5 Buy correction and changes only the scanner manual-code accessibility ownership found defective on Redmi:

- `Cancel` and `Find product` remain visibly pinned above the keyboard;
- each action has one explicit, enabled button semantic with a non-zero 44dp on-screen rectangle;
- touch behavior, IME submission, automatic scan, `Scan now`, torch, camera switch, Back and manual fallback remain unchanged;
- Shop, Store, Wholesale, Bulk, Cart, Checkout, payment, order and tracking behavior remains under the same tested source set.

The APK uses isolated package `com.moolsocial.app.cursorreview`, emulator-backed review data and no production payment/backend settlement. Store-Live, Codex Work, shared Chat implementation, Care/Medicine routing and integration are excluded.
