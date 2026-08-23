# C30S Chrome file chooser timeout — 2026-08-13

## Bounded event

- Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S`
- Authorized destination: Google Play **Internal Testing** only.
- Sealed artifact: `MoolSocial-1.0.0-r60.44-2026081244-release.aab`.
- Expected SHA-256: `2B06AEE022AED4019AE88AF4278A218FEA4F14F3D49F94CDC591DA855458AD55`.

The first browser upload interaction armed the documented file-chooser wait and clicked the first file input accepting `.aab`. Chrome did not emit the file-chooser event before the extension-control timeout. The chooser never returned, `setFiles` never ran, and no AAB was transmitted to Google Play.

## Classification

- Build authority remains consumed exactly once.
- Upload count remains zero.
- No second AAB build is authorized or required.
- The Internal Testing draft must be inspected again before retry to prove it remains empty.
- Production, open testing and public listing remain unauthorized.

## Retry gate

Before a single browser-upload retry:

1. Read the Chrome-specific file-upload troubleshooting guidance.
2. Reconnect to the exact Internal Testing draft without reloading unrelated console surfaces.
3. Prove no app bundle is present in the draft.
4. Recompute and match the sealed AAB SHA-256.
5. Use the documented Chrome-compatible visible upload control or file input flow.
6. Stop on any ambiguous chooser, duplicate upload, wrong track, wrong version code or unexpected external side effect.

## Resolution

After the founder enabled Chrome extension access to file URLs, the retry used Play Console's visible **Upload** control. Exactly one sealed AAB was selected. Play accepted and parsed `2026081244 (1.0.0-r60.44)` with target SDK 36; no second build or second upload occurred.
