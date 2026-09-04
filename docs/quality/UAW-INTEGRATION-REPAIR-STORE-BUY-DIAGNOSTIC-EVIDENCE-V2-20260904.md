# Store-Buy failed-repair diagnostic evidence v2

Ticket: `UAW-INTEGRATION-REPAIR-STORE-BUY-DIAGNOSTIC-EVIDENCE-V2-20260904`

Work ID: `store-buy-diagnostic-evidence-v2-20260904`

Baseline: immutable failed repair `c48e4ecc5c3ccc7a3079d3f64988437599cc78de`

## Scope

This docs-only lane records and reproduces the failed combined regression. It cannot change product or test source, amend or push the failed repair, build an APK, use a device, admit integration or create fix tickets.

Diagnostic v1 commit `3fc346f12b22b7c13fb6c1b47c32ec7317e7be2b` is retained as failed coordination evidence because its artifact root was outside the lane allowlist. Its diagnostic test never ran. The first v2 checkout failed for lack of disk space; after founder-directed cleanup, the existing branch was recreated from the same immutable baseline with 20.317 GB free and zero status records.

## Original command

Working directory: `apps/mobile`

```text
flutter test --no-pub --reporter compact test/work_store_atomic_operations_test.dart test/work_workspace_layout_safety_test.dart test/work_vertical_slice_test.dart test/work_production_gateway_test.dart test/ui_v2/work/work_main_v2_test.dart test/ui_v2/work/work_opportunity_home_c24g_test.dart test/ui_v2/universal/mool_care_work_navigation_conformance_c26f_test.dart test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart test/ui_v2/universal/uaw_personal_social_work_route_compatibility_test.dart test/ui_v2/universal/uaw_r10_personal_work_exposure_test.dart
```

Known result: exit code `1`; `140` passed; `70` skipped; `5` failed.

The complete original output was truncated and never retained. It cannot be recovered or reconstructed. Only the exact command, file list, known totals, available conversation fragments and this explicit evidence gap are authoritative.

## Deterministic rerun

The same ten files run with `--reporter expanded --concurrency=1`. Complete generated stdout, stderr, result and toolchain hashes are retained under `docs/quality/store-buy-diagnostic-evidence-v2-20260904/` before any bounded summary is accepted.

## Comparison matrix

- Store `aa335eb1497d77c859e7d34b549716350612c5c8`: all ten files.
- Failed repair `c48e4ecc5c3ccc7a3079d3f64988437599cc78de`: all ten files.
- Cursor Buy `fd55d1cfffa5ed10f753f2ed24461ef9ac6a9a5d`: nine common files.
- `work_store_atomic_operations_test.dart` on Cursor: **not applicable—file absent**. It is not passed, failed or skipped.

The Store atomic-operations blob is compared separately between Store and the failed repair. The separate `universal_intent_completion_test.dart` Chat-boundary failure is excluded from this investigation.

## Pending evidence

- Flutter and Dart versions
- Relevant dependency hashes
- Serialized raw-log SHA-256 and exit code
- Complete deterministic failing test names, assertions and stacks
- Store/Cursor/repair comparison results
- Ownership classification and minimal proposed child-ticket groups
