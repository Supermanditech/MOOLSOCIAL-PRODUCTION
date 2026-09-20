# r66.36 current-source local qualification

Implementation 6e32df591dc8178aa1776c0f18c2eac0bb4efc37; app tree
818257cadc2064a1f05735414e5a677707533f05. No current device acceptance.

Existing local v29b evidence: 90 connected UI cases and 358 atomic/PDF cases pass,
eight pre-existing skips; 19 focused capture cases pass; full analysis clean.
Retained source-matched reports/logs/screens:
C:/Users/jisal/Documents/Codex/2026-09-19/restock-testing-in-store/outputs/
counter-sale-invoice-status-local-qualification.md
and counter-sale-invoice-status-{journey-03,atomic-pdf-05,analysis-06,capture-07}.log.

The unchanged 45-file pre-APK suite passed twice against this implementation:
2813 passed / 87 skipped in each cycle; cycle 1 20:21, cycle 2 19:41. Exit 0.
Current run logs: counter-sale-r66-36-full45-cycle-01-02.log and
counter-sale-r66-36-full45-cycle-02-02.log under the same outputs directory.
Before/after source snapshots are identical; separate before/after hashes also
confirmed every one of the 45 test owners unchanged. Protected-reference tag
exclusions are inherited, not a newly reduced test scope; skips are not passes.
The 396-entry candidate manifest adds the existing PDF test to the established
395-entry source snapshot, matching the previous candidate's coverage.

SHA256:

- cycle 1: 25313CFFE35EF699304A2A337BE3A4C93CA80F33441AB28150944263173B549F
- cycle 2: D19C126AA125601D2A860F478E1AA4D33D05F5FF9697C20BE016FAFEE0727185
- both source snapshots: 6BB9E4D9949A100EF90182035F1051A1C0F6D486FC383F88E8EE0836A8FB9890

Final candidate-mode checks passed: PDF selection 1, PDF generation 1, Work
isolation 6, Chat isolation 4, relaunch 5 / 1 mode-specific skip. Exact four
r66.36 review defines used; EXPECT_REVIEW_PDF=true was a test-only oracle.
Full Flutter analysis found no issues; formatter checked six files, zero changes.
Build-foundation checks passed with locked dependency resolution; no upgrades.
All 396 candidate source entries were rehashed and remained unchanged. Process
27380 exited 0. No new APK or OPPO qualification is implied by these results.

Narrow successor admission: 64 exact identities and 608 invalid/missing facts
checked; previous r66.35 test set also passes with 64/608. Log:
counter-sale-r66-36-admission-fixtures-04.log. No gate bypass or broadened wildcard.
