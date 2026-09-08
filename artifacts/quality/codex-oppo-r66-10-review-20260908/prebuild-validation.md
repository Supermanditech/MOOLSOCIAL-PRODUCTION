# r66.10 prebuild validation

## Current result — host qualification passed, source seal next

9 September 2026: all required host controls are complete on the unchanged 381-file manifest. Attempt2 completed accepted-commit coverage (18 accepted/2 rejected), positive/omitted/rejected coverage fixtures, approved UI locks, customer copy, full tracked-support self-tests including successful cleanup, and Android resource integrity (11 XML, no unexpected deletion, one launch owner). Attempt3 reran the failed build-foundation step with its existing command-specific EvidenceArchiveRoot parameter and completed the remaining incremental pre_build, MVP execution and guarded locked-dependency checks.

Attempt3 complete command/control log: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/r6610-prebuild-controls3-continuation-20260909.log; SHA-256 4A6A4AC02FA4DEF6F2A7B086C8D4EAAE5F83238748F27E80FCAA801866709FDB; process exit 0. Flutter dependency output was emitted through the wrapper's Out-Host and retained in the complete tool response, not falsely represented as part of this log hash. Resolution used --enforce-lockfile; no package was upgraded; all 381 source and tracked-support hashes matched afterward. The archive default was restored on exit.

Local test/analysis qualification is in local-validation.md. The package remains debug RuntimeUiReview, com.moolsocial.app.runtime, both review flags plus emulator mode, explicitly non-promotable. The original r66.9 APK, rejected/failed runs and founder-approved source history are retained. No Cursor, Redmi, live sign-in, payment, messaging or backend action was performed.

The source must be committed, pushed, exactly remote-equal and clean before recording its exact HEAD in the one-build machine state. Then use only scripts/build-buy-device-review.ps1 with the same invocation-scoped archive parameter for its nested evidence check. This passed host result does not qualify installation, native interaction, physical accessibility, backend security or founder acceptance. Historical failures below remain preserved.

Pending. Candidate is reserved only. Do not build until source-manifest consistency, all required local regressions, analysis, dependency/support, approved-reference, release-resource, ownership and runtime-build gates actually pass, source is committed/pushed/clean/remote-equal, and one-build state is explicitly activated. Older r66.9 passed checks are historical evidence, not automatic r66.10 acceptance.

## Controls attempt 1 — retained failure

9 September 2026: the unchanged support-wrapper self-test assertions passed, but its final cleanup failed at scripts/test-flutter-clean-support.ps1:139: Remove-Item could not access tmp/rel-build-clean-fixture because it was used by another process. Full command exited 1. No later Android/dependency/build controls ran. Do not interpret the earlier printed support-guard pass as a complete pass.

This repeats the existing registered r669PrebuildFixtureCleanup incident; no product regression or new build authority is inferred. Raw command/stdout: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/r6610-prebuild-controls1-20260909.log, SHA-256 3E35C4EEB1F602FEBDF90EFB892D3DDE837F0FDE3CE56B2C5F32E79AC0471F65. Terminating stderr was retained in the tool result: Remove-Item at line 139, The process cannot access the file because it is being used by another process. It is not fabricated into the stdout log.

After process completion, read-only inspection verified that the exact worktree tmp/rel-build-clean-fixture directory is empty, is not a reparse point and has no matching remaining process. The permitted recovery is non-recursive removal of only this empty generated directory, then one unchanged self-test/control retry with a new log. Do not change the fixture assertions, product code, tracked metadata, evidence, SDK, other worktrees or other processes.

The attempted exact non-recursive cleanup was rejected by the execution tool before command creation: blocked by policy. No deletion occurred. Do not retry through another shell, API or indirect test invocation to bypass that denial. The fixture remains a cleanup blocker. No controls attempt2, build activation, APK, installation or device action followed.

Founder subsequently removed the empty directory using the supplied guarded PowerShell command. On resumption, independent read-only verification confirmed the exact fixture is absent; HEAD remains 64030f4660163521431548282622edddb4998d65, clean with zero status records. Coordination implementation and regression-memory gates passed. This resolves only the old-directory cleanup blocker and permits the already planned unchanged controls attempt2. No original evidence or application files were removed.

Complete current-source Flutter qualification is retained in local-validation.md: two 39-file partitioned passes, each 1423 passed/83 existing reported skips/0 failed; fresh full analysis zero issues; five review-only isolation cases passed. Those results do not override the failed support-fixture cleanup or authorize a build. Android resource checks, build-foundation checks, guarded dependency resolution and exact one-build activation still require completion after the blocker is removed.

## Controls attempt 2 — cleanup passed; nested archive input missing

The fresh support-wrapper self-test completed successfully, including cleanup; the generated folder is absent. Coverage (18 accepted/2 rejected), omission/rejection fixtures, approved UI locks, customer copy and Android resource integrity (11 XML, no unexpected deletion) passed. The run then exited 1 inside the build-foundation test's nested regression-memory invocation: its supported EvidenceArchiveRoot parameter had not been supplied, so preserved REG-3955 evidence could not be found in current worktrees. The directly invoked implementation-memory check already passed with the exact approved archive.

Full command/stdout/error/stack: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/r6610-prebuild-controls2-20260909.log. SHA-256 206EAF8CC169F52A19B3722B256297E898DAC969D3967CEAD0B2D6736951B4F4. No source/build/device action followed. This is the existing archiveInvocation incident, not missing product code.

Bounded continuation: use PowerShell's command-specific default parameter only for check-codex-development-regression-memory.ps1:EvidenceArchiveRoot, set to C:/GUARANTEED OUTCOME/MOOLSOCIAL-ARCHIVE-DIRTY-WORKTREES-20260904, during the existing nested runner invocation, and restore its previous value afterward. The checker still validates that archive and every required evidence owner. Do not alter any checker, copy or invent historical evidence, expand owner roots, or waive the build-foundation tests. Retain the passed attempt2 prefix and rerun the failed foundation plus the remaining controls.
