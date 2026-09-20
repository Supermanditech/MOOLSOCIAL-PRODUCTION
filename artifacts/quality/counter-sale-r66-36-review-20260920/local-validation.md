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

## REG4632 inherited-owner regression and bounded repair

Founder authorized registration and correction after v4 integration rejected
the missing historical r66.35 apk-regression-state.json.local. Failed merge
dec622f66acf9287d5f82679bf1ae65a74669043 is preserved unchanged. No APK attempt,
install or new physical acceptance occurred. Failure is in admission metadata,
not application source; old execution records must not be copied or fabricated.

Task fixture work/counter-sale-reg4632-inherited-owners.ps1 reproduced all 16
r66.35 historical-owner rejections among the full 48-owner inventory before
correction (counter-sale-reg4632-before-13.log). After correction, v4/v5 admitted
96 exact owner cases and rejected all 42 wrong/missing identity, unknown path,
ordinary source-owner and empty-inventory cases (counter-sale-reg4632-after-14.log).
The admission gate now calls this full inherited-owner check before merge; an
unknown future candidate owner fails closed until its exact admission exists.

Existing r66.35/r66.36 suites each retain 64 positive and 608 negative passes
(counter-sale-r66-36-admission-regression-14.log). Exact v5 native admission
passes 1 positive / 6 negative cases with all native hashes unchanged
(counter-sale-r66-36-v5-native-admission-14.log). Registry entry
REG-20260920-4632-SUCCESSOR-INHERITED-EVIDENCE-ADMISSION is permanent; generation
4603 is bound to canonical LF SHA256
D77C0CBAC571EC1509A5B239A568414DB93AA5FD337A384000F1076416FADD95.

The already completed app regressions remain source-matched: a new verification
rehashes all 396 source entries unchanged. This correction does not change Dart,
Android source, dependencies, source/version pins, one-build controls or device
acceptance. Replacement integration is v5; current-generation build checks and
fresh-checkout verification are still required before build activation.
