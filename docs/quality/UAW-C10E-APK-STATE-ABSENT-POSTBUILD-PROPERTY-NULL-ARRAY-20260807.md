# C10E APK-state absent postBuildGates property

Date: 2026-08-07

Ticket: `UAW-PERSONAL-MVP-GLOBAL-NAVIGATION-MOTION-CONTAINMENT-OPPO-FIX1-C10E`

A bounded inspection correctly printed the machine-state root properties but
then evaluated `@($state.postBuildGates).Count` even though `postBuildGates` is
not a root property in the current schema. PowerShell's null-to-array behavior
misleadingly emitted `postBuildCount=1`. No machine state was changed.

The false scalar is rejected. Successor-state preparation first verifies each
required root property exists and uses the actual `qualificationResult`,
`founderVisibleNavigationAcceptance` and `buildResult` owners. Missing optional
properties are reported as absent and are never counted through array coercion.
