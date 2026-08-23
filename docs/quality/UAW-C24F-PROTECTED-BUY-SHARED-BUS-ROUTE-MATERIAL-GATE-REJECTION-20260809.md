# C24F protected Buy shared-Bus-route material gate rejection — 2026-08-09

The protected Buy gate rejected C24F after the 43-owner tree changed from
`a81375a1439f7d9e151ecbf8581c4d576418e953247553cd92a158471c8eee05` to
`43f8b6338c0e4766f7ecc54e4b1ec7266e1be76295e4e08118be82b0d7ff2e6d`.

The protected boundary includes `journey_router.dart`, and C24F necessarily
adds the founder-authorized `/app/book/bus` route there. No Buy business owner
was intentionally changed. Runtime mutation is stopped while the exact delta
and complete Buy suite are audited.

The R40.3 approved baseline and the C24B3/C24D successor seal remain preserved.
Any reconciliation must create a separate candidate seal pending OPPO review;
it may not overwrite or weaken either predecessor.
