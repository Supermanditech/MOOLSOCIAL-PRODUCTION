# r66.5 prebuild validation

Final frontend source is locally qualified for one RuntimeUiReview debug candidate. This is not production release, backend or founder visual acceptance.

- Source:376 manifest owners; SHA-256 F06DECD5EE139E6C01163354DF42506EB892EE8F475196B19BB0A05A156D9673. All current bytes matched after both connected runs.
- Formatting: six functional files, zero changes; git diff --check passed.
- Analysis: zero issues. Two identical38-file cycles each1315passed/83unchanged exclusions/0failed. Native89-case suite passed;156 captures and their exact hashes retained. See local-validation.md.
- Approved commit coverage:18 approved retained,2 rejected excluded; omission/rejection fixtures passed.
- Approved UI references and production locks: passed; no protected reference regenerated.
- Customer-facing copy: passed.
- Tracked Flutter support: passed success/failure/restore/lock fixtures. Locked pub resolution completed without dependency upgrades; the guard preserves approved generated metadata.
- Android resources:11 XML owners; zero unexpected deletions; one launch owner. No Android source change.
- Existing public-auth/sideload build controls: passed with the preserved evidence archive explicitly supplied to nested memory checks. Play/private account actions are not qualified or performed.
- Incremental pre_build and MVP execution gates: passed for the exact Codex UI ticket and r66.5 runtime candidate.
- Original failed attempts, old APKs and device evidence remain untouched. No production/Redmi/Cursor action, integration, payment or message was performed.

Final controls log: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/r665-finish-prebuild-controls2-20260907.log; SHA-25630D0C3127847C250D5E4EB3BCBFA8FC6D90B13570AC9158ACB0A190FFF062F04. The first controls attempt failed only because the nested archive path was omitted; it remains preserved and is not a pass. The corrected invocation uses the existing archive parameter, not a weakened checker.

Package isolation: com.moolsocial.app.runtime, version1.0.0-r66.5-runtime/code2026090604, debug, non-promotable. Exact runtime defines are UI_REVIEW_ONLY=true, DEVICE_REVIEW=true, USE_EMULATORS=true and candidate ID UAW-CODEX-OPPO-R66.5-REVIEW-20260907 (all with MOOLSOCIAL_ prefixes). No real identity, collection, payment, rider or admin authority is inferred from review fixtures.

Pending source-seal step: run the current pre_commit gate on the exact19 owners, commit/push, verify clean state and exact remote equality. Only then bind the machine state to that sealed HEAD for one guarded build. APK integrity, update-install, OPPO replay and founder review are subsequent distinct gates.
