# C30Y prebuild regression-memory build-mode deadlock

- Incident: `REG-20260814-2173-AAB-C30Y-PREBUILD-REGRESSION-MEMORY-BUILD-MODE-DEADLOCK`
- Candidate: `UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE`
- State at discovery: source qualified; build/upload/install counts `0/0/0`

The read-only prebuild replay proved that `scripts/check-successor-aab-regression-hard-gate-c30x.ps1` invokes regression memory with `-Phase build -BuildMode none`. `scripts/check-codex-development-regression-memory.ps1` explicitly rejects `none` for build phase and its validation set does not represent the actual `release` build type. This is a fail-closed release-gate deadlock. No AAB was attempted.

The repair requires one exact successor FIX ticket, a `release` regression-memory mode, a C30X `BuildMode release` invocation, positive and negative contract evidence, and two fresh source cycles because the affected gate owners are sealed source-manifest files.

## Resolution

`UAW-C30Y-FIX1-PREBUILD-REGRESSION-MEMORY-AND-EVIDENCE-TRUTH` added the exact `release` mode, bound C30X to it, and added a both-host cross-owner contract that proves `release` passes while `none` still fails with the exact owner message. Two fresh post-FIX1 cycles passed against the canonical 1,125-file manifest `713C86050A8EAE17F067B4B7043D3B46E4DEEC5ABC24BB939A193E1F65DAC190`. The final pre-prompt replay also passed regression memory with `phase=build; buildMode=release`; counts remain `0/0/0`.
