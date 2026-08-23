# C30I Android root focus edge suppression completion

State: `SOURCE_QUALIFIED`; native successor proof required.

- OPPO reproduction proved a raw hardware-key event caused Android's default focused-View fallback to frame the complete Flutter root with green vertical edges.
- Day and night API-26 `NormalTheme` resources now set `android:defaultFocusHighlightEnabled` to `false` while preserving their existing parent and navy window background.
- Flutter continues to own control-level focus visuals, semantics and actions; no Social layout or navigation code changed.
- Focused resource contract: 2/2 passed; both XML resources parse.
- Full Flutter analysis: clean.
- User-facing copy gate: passed.
- Current complete Social inventory v2: 26 files; SHA-256 `C162FED86D91F1F29E0B4242CBE0EC18848343C2FB7639E39D95D8C702834EE2`.
- Qualifying cycle 1: 153 passed / 1 intentionally skipped; log SHA-256 `830425E2DDFB8FDB69B8627FAD633FF1343EACF9DC9AE923653378CC4483C233`.
- Qualifying cycle 2: 153 passed / 1 intentionally skipped; log SHA-256 `D03C29705F5A0B7B6E543C0CAA52FE19FC8D6DF71CD9E58084AB32D9A2866C43`.
- Historical C17c/C20d and reference-capture owners remain preserved and explicitly dispositioned; none were edited or weakened.
- r60.38 remains installed, rejected and preserved. C30I performed no APK build/install, backend/provider/Firebase/Production deployment, credential access, commit or push.
