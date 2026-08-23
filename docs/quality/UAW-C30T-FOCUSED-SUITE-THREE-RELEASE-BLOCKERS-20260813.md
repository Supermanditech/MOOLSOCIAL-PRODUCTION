# C30T focused-suite three release blockers — 2026-08-13

## Failure inventory

Qualification cycle 1 passed static readiness, formatter and analyzer, then reported three focused Flutter failures:

1. `social_v2_moolsocial_feed_ownership_test.dart` retained a removed `_choiceByWorld['social'] = 'create'` source-string expectation.
2. C29O reported a real 14-pixel Videos `RenderFlex` overflow at 140% text.
3. C27D's six-family helper called `single` when the expected family widget was absent.

## Impact

- Backend verify, provider qualification and source sealing were not reached.
- No AAB, upload, install or external mutation occurred.
- Build count remains zero.

## Required recovery

Audit and correct each item separately, run the exact three tests, then restart the complete qualification cycle.

## Resolution

- Feed ownership now asserts the real `_openCreationGateway` behavior boundary.
- The Videos title contracts within the 320x568 viewport at 140% text without overflow.
- C27D verifies the distinct Social compliance dock, the authenticated full-screen Create branch, real Close-to-Feed behavior and subsequent Shorts navigation.
- `flutter analyze` passed with no issues.
- The exact three-test partition passed all six test cases on 2026-08-13.
