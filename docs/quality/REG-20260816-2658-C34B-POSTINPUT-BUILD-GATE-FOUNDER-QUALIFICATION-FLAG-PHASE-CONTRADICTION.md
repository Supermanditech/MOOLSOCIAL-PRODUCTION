# REG2658 — C34B post-input build-gate phase contradiction

## Classification

- Exact incident: new C34B release-control defect in the recurring candidate lifecycle/state-gate family.
- Not observed: app-source regression, authentication regression, Flutter or Gradle build failure, Play upload, OPPO install or runtime failure.
- Candidate effect: C34B r60.66 is rejected and must not be retried, uploaded, installed, repaired or reused.

## Sanitized observation

The founder-owned visible launcher passed the C33G FIX4 blocker gate and the C34B preprompt gate, accepted all three hidden inputs, announced fresh release preflight, passed C33G FIX4 again, and then stopped after cleanup without a postbuild result. Repository reconciliation found build, wrapper, upload, install and device-acceptance counts all zero; the exact retained AAB path and release `google-services.json` transient were absent; the machine state had been restored to the sealed prompt-required state with all founder qualification and agent-read flags false.

No hidden value, terminal state, environment value, credential file or private signing path was inspected.

## Root cause

The launcher writes the three founder-qualified runtime-input flags as `true` after validating the hidden inputs and immediately calls the generic AAB wrapper. The wrapper replays the candidate gate with `-Phase build`. C34B's build phase requires the same three flags to be `false`, because the earlier C33Z preprompt defect was prevented without separating the preprompt and postinput lifecycle moments. A valid post-input state therefore necessarily fails the build gate before the wrapper can record an invocation or call Flutter.

## Permanent prevention

The exact successor must define and test two distinct phases before its source seal:

1. `preprompt`: sealed prompt-required state; hidden-input and founder-qualification flags false; authority available once; all action counts zero.
2. `build`: declared founder-inputs-validated build state; founder-qualification flags true; agent-read flags false; authority still available once; all action counts zero until the wrapper lawfully consumes it.

The launcher must call `preprompt` before any hidden prompt, persist the exact postinput state only after founder validation, and let the generic wrapper call `build`. Static owner checks, failure-path self-tests and both PowerShell hosts must prove the full transition before two fresh full regressions and a new one-build authority are exposed.

## Retained evidence

- `config/codex-development-regression-registry.json`
- `config/successor-aab-regression-hard-gate-state-c34b.json`
- `config/successor-aab-regression-hard-gate-aggregate-c34b.json`
- `tmp/run-c34b-r60-66-single-aab-founder.ps1`
- `scripts/check-uaw-c34b-r60-66-authentication-no-regression-release-readiness.ps1`
- `scripts/invoke-play-internal-aab-build-c30t.ps1`
- `docs/quality/UAW-C34B-R60-66-POSTINPUT-BUILD-GATE-PHASE-CONTRADICTION-REJECTION-20260816.md`
