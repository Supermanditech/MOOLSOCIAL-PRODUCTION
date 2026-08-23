# C30O Play app-ID live-URL / machine-state mismatch rejection

- Date: 2026-08-12
- Scope: Google Play app-container identity
- Result: machine-state identity rejected before further browser action

## Mistake

The C30O machine state and initial container evidence recorded Play app ID `474778280777295872`. After the official Chrome extension connected, the fresh signed-in Play Console tab returned the authoritative app-scoped URL with app ID `4974778280277295872`.

## Root cause

The app ID was manually transcribed from the early Console session and lost digits instead of being qualified against the exact live app URL.

## Permanent prevention

Treat the current signed-in Play app URL and its exact 19-digit app path segment as authoritative. Before any upload, signing, tester-link, App Check, or reviewer-link use, correct every bounded C30O machine/evidence occurrence, rerun the permanent gates, then claim the exact tab whose URL contains the corrected app ID. Never infer or abbreviate an opaque Play app ID.

## Safety outcome

No release, artifact, signing identity, Firebase configuration, tester change, device action, or communication occurred after the mismatch was discovered.
