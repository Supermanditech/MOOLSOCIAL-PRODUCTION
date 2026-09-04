# r65.10 candidate contract

Candidate: `UAW-BUY-V2-R65.10-CURSOR-ORDER-KEY-FIX-20260904`

This successor preserves every r65.9 correction and fixes only retained Orders rendering. Row identity now combines purchase group, row occurrence and visible business order ID, so repeated provider-generated delivery IDs cannot collide. Visible order references, grouping, invoices, primary actions and tracking navigation are unchanged.

The isolated `com.moolsocial.app.cursorreview` package uses review data and no production payment/backend settlement. Store-Live, Codex Work, shared Chat implementation, Care/Medicine routing and integration are excluded.
