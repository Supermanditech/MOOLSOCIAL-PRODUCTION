# UAW C32N-C32P Buy shared-router attribution and test successors focused validation

Date: 15 August 2026
Active ticket: `UAW-C32P-PERSONAL-MVP-BUY-ROUTER-C26D-LOCAL-RAIL-TEST-TOPOLOGY-SUCCESSOR`
State: focused source validation passed; protected successor baseline and complete C28E qualification remain held.

## Exact protected-tree finding

- Approved FSC06 43-file tree: `6e2c18af399d8c2e0a3ab8cb63d76d5e32228f2ea69d26f0d1df662c3f3bbd8e`.
- Current 43-file tree: `12a9880a51c172f060133a90bcffc38d84f68959ff1caf88e13be43e86631bc5`.
- Historical shared `journey_router.dart`: `a98bc91ffaff2d5205e14d258097650d2de7e2a67c214c51ca00ebb312a71429`.
- Current shared `journey_router.dart`: `758eb64038abc04e6e85a4bf053c2148f180d93964c998165d4cbf6744f2319f`.
- Replacing only that one hash in the current inventory reconstructs FSC06 exactly. The other 42 current protected owners are therefore byte-compatible with the approved tree computation.
- No Buy catalogue, saved, cart, checkout, payment, order, provider, session or business owner drift is indicated.

The C24F saved-store manifest row contains a previously documented 62-character token. It remains immutable and is not treated as source drift.

## Test successors

C32O migrated the old Buy router test from the noncompact launcher key to `mool-compact-launcher`. C32P then migrated its remaining predecessor topology to C26D: the compact chooser selects the Buy family/Shop root, while Wholesale and Orders use the persistent Buy local rail. Runtime and baseline files were not edited.

## Initial focused cycles

Two identical cycles passed a 61-file manifest with fingerprint `8000FC82468EB676013503CA97ABB82A86CB209A7513A5A49F9CBF0FFD87826F`. Each cycle passed:

- regression memory, MVP scope/delivery and approved UI locks;
- C32N, C32O and C32P on PowerShell 7 and Windows PowerShell (`6` host-script runs);
- `49` connected Flutter tests across authentication/session, public Feed/auth return, C26D Social/Shop, Buy route continuity and all nine Buy router cases; and
- analyzer over seven exact Dart files with zero issues.

Because the scope state is included in the manifest, the passed/held status was then recorded and the initial fingerprint was not used as final evidence.

## Final-state rebind cycles

Two further identical cycles passed the permanent state with the exact 61-file fingerprint `A9B630FE467488B72F3E8EECAF60FC3ED8FF2B180939CD96F7570ED44B73AD05`. Each repeated all `49` Flutter tests, `6` dual-host gate runs, scope/delivery/UI/memory gates and clean seven-file analysis. The sealed 61 files were unchanged before and after both cycles.

Exact manifest: `artifacts/quality/uaw-c32n-c32p-buy-shared-router-attribution-20260815-01/source-manifest-c32n-c32p.txt`.

This is focused qualification of the attribution and test successors only. The complete C28E preflight is not qualified and remains held pending a founder decision on a versioned Buy successor baseline.

No protected baseline update, full C28E retry, backend/provider/build/Play/OPPO/credential/funds/external action occurred.
