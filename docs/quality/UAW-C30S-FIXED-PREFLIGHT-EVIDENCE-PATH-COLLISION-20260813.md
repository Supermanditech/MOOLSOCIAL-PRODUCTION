# C30S fixed preflight evidence path collision

Date: 2026-08-13
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-FIREBASE-STARTUP-RECOVERY-C30S`

The corrected founder inputs passed. Before any Gradle or Flutter invocation, the wrapper rejected because `03-release-config-only.log` already existed from the earlier fail-closed manifest-permission investigation. The wrapper correctly refused to overwrite evidence, but had no distinct namespace for another non-consuming preflight attempt.

Read-only reconciliation proved authority `available_once`, build count `0`, wrapper invocation count `0`, config-only count `0`, both transient files absent, and no sealed r60.44 AAB. Existing `03` and `04` logs remain preserved.

The correction keeps the final AAB path single and fixed while selecting the first completely unused bounded preflight-attempt suffix for config log, manifest log, build log, prebuild state, merged manifest, merger blame and provenance. Selection must be atomic at wrapper start, capped fail-closed, and recorded in provenance. Build authority remains untouched until the selected preflight succeeds.

Regression: `REG-20260813-1629-C30S-FIXED-PREFLIGHT-EVIDENCE-PATH-COLLISION`.
