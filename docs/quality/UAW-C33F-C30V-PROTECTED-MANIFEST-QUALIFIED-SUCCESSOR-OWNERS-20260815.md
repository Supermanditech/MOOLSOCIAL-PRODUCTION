# UAW C33F C30V protected manifest qualified successor owners

Date: 2026-08-15
Regression: `REG-20260815-2365-C33F-C30V-PROTECTED-MANIFEST-EXCLUDES-QUALIFIED-SUCCESSORS`
Ticket: `UAW-C33F-R60-49-GOOGLE-AUTH-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE`

The read-only C33F preflight counted 209 current protected Social/YouTube/Chat owners while the historical C30V manifest generator requires exactly 206. Comparing the current protected path set with the sealed C30Y source manifest identified exactly three qualified successors:

- `apps/mobile/test/uaw_c33e_fix3_social_auth_rollback_independent_cleanup_test.dart`
- `apps/mobile/test/uaw_c33e_fix4_protected_social_action_intent_return_continuity_test.dart`
- `backend/functions/src/chat/attachment_store.ts`

The old generator would therefore reject the correct current source set before any test or build. Recovery under the selected C33F release-qualification scope is to retain the 206-owner sealed baseline, require these exact three successor paths, require a total of 209 unique protected paths, and continue rejecting every unexpected addition or omission. No protected runtime source, UI, route, provider or backend behavior changes.
