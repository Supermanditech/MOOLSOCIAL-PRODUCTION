# Buy V2 r65.1 Cursor review pre-build validation

- Candidate: `UAW-BUY-V2-R65.1-CURSOR-75-DEFECT-REVIEW-20260903`
- Version: `1.0.0-r65.1` (`2026090301`)
- Profile: non-promotable `CursorUiReview` debug APK.
- Branch: `work/cursor-ui/buy-mvp-ticket14-v1-20260902`
- HEAD: `fbc39fb4d6bc5ce3fb3ffd33063c273084634dc5`
- Source manifest: 702 files; SHA-256 `FEEFDEDF67F75A7EE60A6B5A9E5B9ADE9D195299EFC79E059F3E5F34CE0A70FA`.
- Full isolated `flutter analyze --no-pub`: zero issues.
- Affected Buy regression cycle 1: 279 passed.
- Affected Buy regression cycle 2: 279 passed.
- Claimed-owner `git diff --check`: passed.
- Worktree status: 25 modified records, all within the recorded Cursor Buy claim; porcelain SHA-256 `F0549B7556CD9380BF69A8F38A548D8418CCAC00D342F73E76AB3B03D9BF4451`.
- Cursor UI review profile self-test: passed.
- Release artifact path containment: passed.
- Production plugin-integrity fixtures: passed.
- MVP execution gate: passed; candidate remains UI-review-only and non-promotable.
- Protected prior-revision visual captures are preserved. Five changed checkout/cart goldens are held for founder review and were not overwritten.

This evidence authorizes one debug build only. It does not authorize integration, promotion, release, commit or push.
