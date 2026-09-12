# r65.8 candidate contract

Candidate: `UAW-BUY-V2-R65.8-CURSOR-VALID-PAYMENT-CHOICE-20260904`

This successor preserves every r65.7 correction and closes the stale-selection defect:

- the Checkout CTA is enabled only when the selected value matches a payment choice currently rendered for this order;
- empty or ineligible retained choices, including Purchase order on a Shop cart, show disabled `Choose payment method`;
- selecting PhonePe, Paytm, Pine Labs, eligible Cash on Delivery, or eligible Wholesale/Bulk Purchase order enables the existing next step;
- all scanner, Shop, Store, Wholesale, Bulk, Cart, order and tracking behavior remains unchanged.

The isolated `com.moolsocial.app.cursorreview` package uses review data and no production payment/backend settlement. Store-Live, Codex Work, shared Chat implementation, Care/Medicine routing and integration are excluded.
