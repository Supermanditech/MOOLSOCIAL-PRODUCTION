# REG-20260812-1392 — C30I test evidence relative-path escape rejection

- Phase: C30I focused-matrix evidence retention
- Failure: From `apps/mobile`, the relative path `../../../artifacts/...` resolved to `C:\GUARANTEED OUTCOME\artifacts\...` rather than the production repository's `artifacts/quality/...` directory.
- Gate effect: REG1391 referenced the intended repository path, so the permanent regression gate correctly rejected the missing evidence.
- Permanent prevention: Resolve and print the absolute evidence directory before running a test. Require it to start with `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION\artifacts\quality\` and pass an absolute path to the log writer.
- Repair: Copy the generated log to the intended repository evidence path after validating both absolute locations; retain the original rather than deleting it.
- Protected state: No source, build, install or deployment change resulted.
