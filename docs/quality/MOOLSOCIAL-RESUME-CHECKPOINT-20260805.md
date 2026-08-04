# MoolSocial exact resume checkpoint — 5 August 2026

## Recovery target

Production content commit:
`da656725c33bff7be42c190761892dc1d6a816bb`; tree
`512abcadf3d214fea65857aaeea2326edf0d4510`.

Use Git branch `checkpoint/moolsocial-20260805-0055-ist-sealed` as the immutable
resume pointer. It points to the same sealed commit as the required working
branch `remediation/prototype-conformance-2026-07-20`; no branch switch was used
during sealing and `main` was not changed.

The requested cut was 5 August 2026 00:55 IST. The cut includes only the
necessary post-cut completion of the already-active R58.8.8 FIX7 qualification,
founder approval and repository seal. No successor ticket was started.

## Current approved runtime identity

- Candidate: `BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7`
- Founder disposition: approved/protected
- Profile: `1.0.0-r58.23 (2026080419)`
- Source: 2,466 files, SHA-256
  `A05B47F0893778064E255574DF3678BF198DAE72A18DA7C81710693557AE1BEE`
- APK/install: 134,214,109 bytes, SHA-256
  `F0C1061D1D7897130528533F254B41BDC48FE7958E7DD9B50624FEF6EE3B5DC9`
- Technical evidence: folder `175`
- Founder decision: folder `177`
- Machine state: `founder_approved_protected`; one-build authorization consumed
- Protected-baseline file replaced: no

Codex is satisfied with the OPPO qualification. Direct accessibility, exact
checksum, full affected journeys, process recreation, focus/keyboard/Close/
Back, visible reduced motion with `1/1/1` restoration, performance, runtime
failure scan and final source identity passed.

## Repository state captured before sealing

- Working branch: `remediation/prototype-conformance-2026-07-20`
- Pre-seal HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Remote branch observed before seal:
  `646cf6ffb69802ec3986c6ed5dc467183192e353`
- Local branch was already 23 commits ahead of the remote before this seal.
- Tracked dirty files before the checkpoint: 39.
- Untracked files before checkpoint generation: 47,536 / 77,224,427,128 bytes.
- Local artifact/tmp identity: folder `176`, manifest SHA-256
  `49CED5F8D2B52452D5946DB0FD999B186CA84AF7B4694FA8DAA140283A9A93F7`.

## Included production state

The Git checkpoint contains the complete current Flutter source, navigation,
motion, search relevance, Buy/session models, tests and goldens; current Social
and splash changes; release/machine gates; delivery/design/quality memory; new
commerce participant, canonical catalogue and wholesale pack/logistics backend
contracts plus tests; non-secret fail-closed Dev flags; and the exact current
review APK through Git LFS. Backend verification passed 317/317 tests. R58.8.8
passed two 359-active Buy regressions plus all registered release gates.

## Resume procedure after laptop loss

1. Clone the production repository and fetch all branches and Git LFS objects.
2. Check out `checkpoint/moolsocial-20260805-0055-ist-sealed` for recovery, or
   the remediation branch if continuing authorized work.
3. Run `git lfs pull` and `git lfs fsck`.
4. Verify the r58.23 APK SHA-256 equals
   `F0C1061D1D7897130528533F254B41BDC48FE7958E7DD9B50624FEF6EE3B5DC9`.
5. Verify `config/apk-regression-gate-state.json` reports the exact approved
   candidate and consumed build authorization.
6. Re-run focused formatting/analysis/tests and the required release gates
   before any new ticket write. Register a unique successor before another APK.

## Next work boundary

R58.8.8 is closed and founder approved. No next runtime candidate is registered
or pre-authorized by this checkpoint. Dependency-held taxonomy/pagination,
stock, serviceability, personalization, payment/order/provider outcomes and the
broader production-foundation backlog remain governed by their own tickets and
environment gates. No GCP/Firebase deployment or environment promotion is part
of this seal.
