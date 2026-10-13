# r65.9 candidate contract

Candidate: `UAW-BUY-V2-R65.9-CURSOR-PAYMENT-BRAND-COPY-20260904`

This successor preserves every r65.8 correction and fixes only customer-facing payment-provider casing. Known slugs render exactly as `PhonePe`, `Paytm` and `Pine Labs`; unknown values retain a safe title-cased fallback. Payment validity, scanner, Shop, Store, Wholesale, Bulk, Cart, Checkout, order and tracking behavior remains unchanged.

The isolated `com.moolsocial.app.cursorreview` package uses review data and no production payment/backend settlement. Store-Live, Codex Work, shared Chat implementation, Care/Medicine routing and integration are excluded.
