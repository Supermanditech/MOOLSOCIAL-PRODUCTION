# RV6-D014 corrective Redmi qualification

Candidate: UAW-CURSOR-REDMI-RV6-D014-20260914, r66.23/code 2026091404.
Source evidence HEAD: 1d5c4be97dc13874af1f4348156782339ecacf60.
Application correction: 4221158fead95a89047e3408aaeb11c9a12dd135.
Only device: Redmi TG8HCYTGGQT885OF. Only package: com.moolsocial.app.cursorreview.

All checks below are pending. This plan is not device evidence.

Before installation, require terminal build success, verified APK identity/signer/provenance and preserved prebuild state. Upgrade with data preserved. Compare installed base.apk SHA256 with the verified artifact before acceptance captures. Preserve original English and font scale, Cart, Saved product identity and selected address. Do not add an order, send a message or clear data/history.

| Case | Actual entry/state before the declared order link | Required result |
| --- | --- | --- |
| Original, normal text | Recently viewed > Adult dog food > Pet Family Store > Other Store > Android Back | Original Store is visible before the link; existing MS-240782 tracking and Orders selection remain after it |
| Original, 200 percent text | Same real nested product and returned Store route | Same order destination, legible actions and successful return; restore original scale afterward |
| Shop Store | Product Store overlay before Other Store navigation | Native order link dismisses the overlay without an assertion or lost destination |
| Shop Other Store | Other Store overlay still open | Same order identity and safe return |
| Shop full catalogue | Store View more/full catalogue | Same order identity and safe return |
| Shop missing order | Full catalogue, declared order link for missing-order | Honest unavailable/recovery UI, no fabricated existing order; safe Shop/Orders return |
| Wholesale Store | Existing notebook supplier overlay | Same existing order identity and safe return |
| Wholesale Other Store | Other supplier overlay still open | Same existing order identity and safe return |
| Wholesale returned Store | Other supplier then Android Back | Same existing order identity and safe return |
| Wholesale full catalogue | Supplier View more/full catalogue | Same existing order identity and safe return |

Use settled screenshots and hierarchy dumps to establish each starting state and result. Retain native ACTION_VIEW receipts and app-scoped failure diagnostics. Verify Saved/Cart/address preservation through the affected returns, and restore the original user context. Avoid repeating other already-closed defects.

The local 21-case matrix additionally covers opening-motion delivery and all listed text-scale variants. Report local coverage separately; do not imply each combination was physically tested from a smaller device subset. If any required physical case is unreachable, record the exact missing fixture or blocker and keep its acceptance open.

Final Git handoff remains separately failed by historical commit 448d4a2c's subject. This plan neither admits that label exception nor establishes production, backend, provider or integration acceptance.
