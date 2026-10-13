# r65.7 candidate contract

Candidate: `UAW-BUY-V2-R65.7-CURSOR-PAYMENT-PREREQUISITE-20260904`

This successor preserves every approved r65.6 Buy correction and changes only the Payment prerequisite presentation found defective on Redmi:

- no payment selected: disabled `Choose payment method`, no tap action and no silent failure;
- valid method selected: enabled `Review order` with the existing confirmation navigation;
- PhonePe, Paytm, Pine Labs and eligible Cash on Delivery remain customer-facing choices;
- scanner, Shop, Store, Wholesale, Bulk, Cart, Checkout, order and tracking behavior stays under the same tested source set.

The APK uses isolated package `com.moolsocial.app.cursorreview`, emulator-backed review data and no production payment/backend settlement. Store-Live, Codex Work, shared Chat implementation, Care/Medicine routing and integration are excluded.
