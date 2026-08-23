# C30N C30M build-control historical-candidate coupling rejection

- ID: `REG-20260812-1471-C30N-C30M-BUILD-CONTROL-HISTORICAL-CANDIDATE-COUPLING-REJECTION`
- Date: 2026-08-12
- Scope: local C30N source-qualification cycle 1r
- Result: cycle rejected before analysis/tests; no APK build, install, cloud, device or content mutation occurred

The C30M Social endpoint negative-control suite invoked the APK gate against
its historical default machine candidate while the MVP scope gate correctly
required the active C30N ticket. The MVP candidate mismatch therefore occurred
before the intended missing-endpoint rejection. The partial cycle is rejected
and preserved. The control accepts an explicit machine-state path and runs its
negative variants from the exact active C30N state so successor scope and the
asserted endpoint failure remain independently truthful.
