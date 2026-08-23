# C30T YouTube public read rejected on Play-installed r60.44 — 2026-08-13

The OPPO Play installation is `1.0.0-r60.44 (2026081244)`, installer `com.android.vending`, signed by the registered Google Play app-signing certificate. Startup reaches a stable Flutter frame, but YouTube Home shows:

- `YouTube Videos could not load`;
- `Videos are unavailable right now. Please try again.`;
- a visible **Try again** action.

Two no-tap screenshots are byte-identical with SHA-256 `54FF893119449403EB0A0D4F3F6E28E314AF159A2FE467EE583FC3ED969B52AE`, proving a stable error frame rather than a startup crash. The founder separately attempted Videos and Shorts and reported neither loads.

No private Play Integrity/App Check verdict, nonce, token, API key or attestation payload was read. The root cause remains unconfirmed. This blocks the YouTube reviewer journey and all YouTube compliance/quota communication.
