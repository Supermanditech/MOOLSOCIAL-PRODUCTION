# UAW C30U Chat owner protected-inventory inference without membership proof

Date: 2026-08-14

## Incident

The attempt-5 copy-repair record initially stated that
`apps/mobile/lib/features/chat/chat_services.dart` belonged to the C30U
protected Social successor and required resealing. That conclusion had not been
proved from the baseline manifest.

## Exact reconciliation

A no-match-safe exact-path query returns zero matches in both verified owners:

- C30U successor `BASELINE.json`: 0
- C29E predecessor `BASELINE.json`: 0

The Chat source repair therefore changes the broader qualification source
fingerprint but not the 206-file protected Social portable tree.

## Prevention

Never infer file membership from an audit's narrative scope. Query the exact
relative path against the current and predecessor baseline manifests first.
Only a proven member authorizes a transparent successor reseal; zero matches
require replaying the existing unchanged gate.

No baseline was rewritten and no release or device mutation occurred.
