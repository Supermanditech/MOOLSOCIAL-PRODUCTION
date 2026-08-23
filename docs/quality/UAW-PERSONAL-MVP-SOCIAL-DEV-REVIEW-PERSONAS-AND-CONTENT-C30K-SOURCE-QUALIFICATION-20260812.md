# UAW Personal MVP Social Dev review personas and content C30K source qualification

## Outcome

C30K source is qualified. A guarded non-HTTP runner now defines three deterministic disabled passwordless Firebase Auth review personas and exactly 36 idempotent Dev posts:

- 12 `post` records: six text-only and six with one image;
- 6 carousels with three images each;
- 6 Image Polls with four image choices each;
- 6 Quick Polls with four choices each;
- 6 Quizzes with four answers and one valid correct answer each.

The 48 small review images are valid PNGs generated in memory. Publishing reuses `SocialContentService` and `FirestoreSocialContentRepository`, so existing format validation, authoritative Auth author identity, media verification, server-side Storage, Firestore ordering and idempotency remain the only write owners.

## Guardrails

- Dry-run is the default and reported `writesPerformed: false`.
- Apply requires `--apply` and exact project `moolsocial-dev-503018`.
- Existing persona identity mismatches fail closed without update or overwrite.
- Personas have no password, phone number or linked provider and remain disabled.
- The runner does not mint a custom token, print a credential, expose an HTTP function or relax direct-client rules.
- Reruns reuse stable publish idempotency keys.

## Qualification evidence

- Backend TypeScript typecheck: passed.
- Focused corpus tests: 3 passed.
- Guarded dry run: 3 personas, 36 posts, 48 media objects, zero writes.
- Wrong-project apply guard: passed before authentication.
- Complete backend suite: 498 passed, 0 failed; log `artifacts/quality/uaw-c30k-backend-suite-20260812-01/npm-test.log`; SHA-256 `24AAE71B0E5A1932B6989C83E55A54C225CCB78D9BC2FC7493CFC64E9B4109F6`.
- Firestore and Storage deny-all emulator gate: 2 passed, 0 failed; log `artifacts/quality/uaw-c30k-rules-emulator-20260812-02/firebase-emulator.log`; SHA-256 `9ADEE44343C9D67732337024C157D65A63C9A24029710D5FE5DCF2CB1ED45E35`.
- Flutter authenticated gateway and all-format render matrix: 11 passed.
- Flutter analysis: clean.
- User-facing copy gate: passed.
- Focused C30K machine gate: passed with external writes, APK and deployment all false.

## External Dev apply gate

No Auth user, Firestore post or Storage object was created during source qualification. The local Firebase Admin authority probe returned `app/invalid-credential`; the gcloud user session alone is not Application Default Credentials. The founder must complete the visible ADC login before the ticket can transition to an external Dev apply state.

## Protected device and delivery state

No APK was built or installed, no backend or rules deployment occurred, and rejected OPPO candidate `1.0.0-r60.38+2026081238` remains installed and preserved with all C30H evidence. Deployment remains held.
