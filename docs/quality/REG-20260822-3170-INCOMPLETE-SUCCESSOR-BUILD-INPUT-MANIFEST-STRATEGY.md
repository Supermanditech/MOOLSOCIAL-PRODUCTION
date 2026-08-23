# REG3170 - incomplete successor build-input manifest strategy

## Classification

Rejected prebuild strategy with zero r60.81 build, artifact or install action.

## Evidence

The proposed successor manifest reconstruction would have reused the preserved
r60.80 path inventory and appended only already-known FIX8 paths. In the
intentionally huge dirty worktree, that method cannot prove that every current
tracked and untracked Android/Flutter build-affecting input is represented.
The strategy was rejected before candidate registration, manifest creation,
Flutter invocation or artifact creation.

## Prevention

Before any FIX8 r60.81 build, derive and seal the complete current build-input
closure from the live Flutter package graph, Android build configuration and
all relevant tracked and untracked files. Cross-check it against the preserved
r60.80 inventory, fail closed on every unexplained omission, and bind the exact
manifest count and SHA-256 into the candidate gate before granting one-build
authority. The dirty worktree must remain preserved and is never treated as a
substitute for a sealed input manifest.
