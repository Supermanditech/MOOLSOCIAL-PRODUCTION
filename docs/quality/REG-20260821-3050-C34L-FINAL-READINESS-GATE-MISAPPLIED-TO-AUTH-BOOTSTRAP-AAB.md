# REG-20260821-3050 C34L final readiness gate misapplied to auth bootstrap AAB

## Observed failure

The retained C34L final-candidate readiness checker was invoked for the new
authentication bootstrap AAB and rejected a changed `lifecycleTransitionPath`.
No build started.

## Root cause

C34L is bound to the retained r60.76 final release-evidence transaction. The
current bootstrap AAB is a non-test, non-release artifact used only to let Play
create/read back the app-signing certificate; it has no C34L lifecycle state.

## Impact

- mandatory regression, coordination, MVP and build-wrapper terminal-state
  gates passed;
- no source, build, signing, Play, OPPO, provider or device action occurred;
- the failed C34L result is not accepted for the later final candidate.

## Prevention and authorized continuation

Do not retry, modify or weaken C34L for the bootstrap. Keep the bootstrap
explicitly unavailable for OPPO acceptance. After Play signing fingerprints are
registered and the final auth AAB is prepared, replay C34L against its exact
final-candidate lifecycle and current interface.
