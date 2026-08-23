# UAW C18C approved-UI gate next Screen03 platform-test mismatch rejection — 2026-08-08

## Result

After the additive Screen01 v4 package and current production goldens were
written, `scripts/check-approved-ui-locks.ps1` advanced beyond Screen01 and
rejected the active Screen03 production lock:

- owner: `apps/mobile/test/platform_configuration_test.dart`;
- expected SHA-256:
  `490721029D88301E42DC593526618B4F94198AB586C1E55D709CAE12776123BC`;
- current SHA-256:
  `DEFFE5CFD7CD7C1432D6057E5C045A1569DC3F71FBD5F9D8EF26251E984A68CA`.

This is a newly revealed independent protected-owner mismatch. C18C does not
retry the gate, modify Screen03, restore a historical test, weaken the checker
or claim v4 qualification before Screen03 provenance is proven.

No app runtime source, APK build, install, uninstall, data clear or downgrade
occurred.

## Prevention

Protected acceptance reconciliation must continue one owner at a time. A gate
that advances to a different screen creates no authority to copy the previous
screen's solution. The exact current file status, history, accepted checkpoint
and later founder-approved evidence must be reconciled before any Screen03
reference or test mutation.
