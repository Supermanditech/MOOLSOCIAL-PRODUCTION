# C30K Firebase emulator target preflight rejection

## Finding

With the Android Studio Java 21 runtime supplied process-locally, the first `emulators:exec` attempt still reported that no emulators were selected. No emulator started and no rule or external data changed.

## Disposition

Rejected and registered as `REG-20260812-1404-C30K-FIREBASE-EMULATOR-TARGET-PREFLIGHT-REJECTION`.

## Permanent prevention

Preflight the exact installed Firebase CLI, pass the repository `firebase.json` explicitly, and quote the comma-delimited Firestore/Storage target argument. Do not edit the locked rules or Firebase configuration merely to repair command parsing.
