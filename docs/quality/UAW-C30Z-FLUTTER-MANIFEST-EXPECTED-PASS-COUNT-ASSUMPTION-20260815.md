# C30Z Flutter manifest expected-pass-count assumption

Date: 2026-08-15
Regression: `REG-20260815-2226-C30Z-FLUTTER-MANIFEST-EXPECTED-PASS-COUNT-ASSUMPTION`
Status: resolved; exact membership delta bound and counted run passed

## Finding

The corrected 59-file wrapper run completed with 418 authored passes, 3
declared skips, zero authored failures, zero error events, zero non-JSON lines,
zero untyped JSON objects and native Flutter exit zero. It still correctly
returned nonzero because the command assumed 420 expected passes from a
remembered broader total rather than this manifest's exact membership.

## Prevention

Every changed test owner's repository-relative path is normalized and checked
for exact membership in the selected manifest. The next expected count is
derived only from the manifest-specific prior baseline plus authored tests in
included owners. The clean native result alone does not authorize changing the
expectation. No build, Play, OPPO, provider, credential or external-service
state changed.

## Resolution

The normalized 59-file manifest contains
`test/release_runtime_configuration_test.dart` but not
`test/screen03_session_test.dart`. The manifest-specific delta from the sealed
417-pass baseline is therefore exactly one. The corrected wrapper run passed
with 418 authored passes, 3 declared skips, zero failures/errors/non-JSON or
untyped events, and native Flutter exit zero. The two new session tests passed
in the separate focused suite.
