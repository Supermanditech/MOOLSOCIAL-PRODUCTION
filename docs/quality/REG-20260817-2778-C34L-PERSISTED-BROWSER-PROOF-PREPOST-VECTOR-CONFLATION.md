# REG2778 — C34L persisted browser-proof pre/post vector conflation

Date: 17 August 2026
State: registered fresh FIX1 fixture failure; no external action

## Mistake

After the REG2777 UTC correction, the fresh PowerShell 7 fixture reached
post-transition persisted-browser validation. The browser proof correctly
retained the pretransition upload authority
`held_postbuild_qualification`, while the atomic `upload-authorized`
transition correctly changed current state to `available_once`. The checker
incorrectly compared the proof vector with current post-transition state and
rejected the positive fixture. The agent stopped without retry or patch;
cleanup completed and no external action occurred.

## Root cause and prevention

Pretransition proof semantics and post-transition state semantics were treated
as one vector. In pretransition mode, compare proof counts/authorities to current
state/aggregate. In persisted mode, validate them against the exact retained
prerequisite lifecycle proof/journal preimage record while separately validating
the documented post-transition state vector and mirrored browser identity. Add
a negative that substitutes current post-state authority into the retained
preimage proof.
