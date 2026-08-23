# C30T C05 Mool overlay-contract miss — 2026-08-13

After correcting launcher keys, the exact Chat tests reached the tap but still expected a navigated `personal-mool-root-v2`. Current navigation intentionally opens `mool-connected-action-navigator` in-place and uses system Back to close that overlay.

Prevention: qualify current Mool behavior as launcher → connected action navigator → system Back → exact owner, using the production overlay key rather than a retired root-route key.
