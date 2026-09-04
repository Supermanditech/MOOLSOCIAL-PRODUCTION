# Store-Buy failed-repair diagnostic evidence

Ticket: `UAW-INTEGRATION-REPAIR-STORE-BUY-DIAGNOSTIC-EVIDENCE-V1-20260904`

Work ID: `store-buy-diagnostic-evidence-v1-20260904`

Baseline: immutable failed repair `c48e4ecc5c3ccc7a3079d3f64988437599cc78de`

## Scope

This lane records and reproduces the failed combined regression. It may not change product or test source, amend or push the failed repair, build an APK, use a device, admit integration or create fix tickets.

## Original command

Working directory: `apps/mobile`

```text
flutter test --no-pub --reporter compact test/work_store_atomic_operations_test.dart test/work_workspace_layout_safety_test.dart test/work_vertical_slice_test.dart test/work_production_gateway_test.dart test/ui_v2/work/work_main_v2_test.dart test/ui_v2/work/work_opportunity_home_c24g_test.dart test/ui_v2/universal/mool_care_work_navigation_conformance_c26f_test.dart test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart test/ui_v2/universal/uaw_personal_social_work_route_compatibility_test.dart test/ui_v2/universal/uaw_r10_personal_work_exposure_test.dart
```

Known result: exit code `1`; `140` passed; `70` skipped; `5` failed.

The complete original raw output was truncated by the tool channel and was not retained. It cannot be recovered or reconstructed. Only the exact command, file list, totals, available conversation fragments and this explicit evidence gap are authoritative.

## Deterministic rerun

The same ten files will run with `--reporter expanded --concurrency=1`. Complete generated stdout and stderr will be retained under `artifacts/quality/store-buy-diagnostic-evidence-v1-20260904/` before any bounded summary is accepted.

## Comparison matrix

- Store `aa335eb1497d77c859e7d34b549716350612c5c8`: all ten files.
- Failed repair `c48e4ecc5c3ccc7a3079d3f64988437599cc78de`: all ten files.
- Cursor Buy `fd55d1cfffa5ed10f753f2ed24461ef9ac6a9a5d`: nine common files.
- `work_store_atomic_operations_test.dart` on Cursor: not applicable because the file is absent; it is not passed, failed or skipped.

The Store atomic-operations blob is compared separately between Store and the failed repair. The separate `universal_intent_completion_test.dart` Chat-boundary failure is excluded from this five-failure investigation.

## Pending evidence

- Flutter and Dart versions
- Relevant dependency hashes
- Serialized raw log SHA-256 and exit code
- Complete deterministic failing test names, assertions and stacks
- Store/Cursor/repair comparison results
- Ownership classification and minimal proposed child-ticket groups
