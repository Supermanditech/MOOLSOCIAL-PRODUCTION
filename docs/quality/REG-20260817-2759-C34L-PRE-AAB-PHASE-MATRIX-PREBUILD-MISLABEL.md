# REG2759 — C34L pre-AAB phase-matrix prebuild mislabel

Date: 17 August 2026
State: registered before correction; no lifecycle or external action

## Mistake

Primary readback of the newly registered PRE-AAB-4 manifest found that its
eight-phase list started with `prebuild`. The established C34L candidate-gate
matrix and predecessor executable fixture start with `preprompt`; the remaining
seven phases are build, postbuild, preupload, postupload, preinstall,
postinstall and journey. No phase-matrix agent had started and no candidate,
seal, cycle, build, Play, browser, device, private or external action occurred.

## Root cause and prevention

The child manifest was drafted from the lifecycle-transition vocabulary rather
than projected from the existing candidate-gate executable phase list. Exact
phase names must be copied from the qualified owner, counted as a distinct set
and compared with all callers before a manifest hash is pinned. The manifest,
batch assessment and machine-state hash pin must be corrected together before
wave-two execution.
