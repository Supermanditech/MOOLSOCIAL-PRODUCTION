# MoolSocial parallel production baseline and worktree handoff

Date: 23 August 2026 IST
State: governance baseline preparation
Runtime baseline: `f105195ba505dcc9f25a35ab64aab104dadb47c2`
Accepted runtime tag: `moolsocial-google-auth-r60.87-accepted-20260823`

## Immutable starting point

The founder-accepted Google Sign-In r60.87 implementation is the runtime
starting point. `main` remains frozen and is not a feature or integration
target. The remediation checkout remains coordination-only once isolated
feature work begins.

No unaccepted file from the legacy reconciliation worktree is merged into this
baseline. The legacy tree is preserved as local evidence because its differing
source and test states were not founder/device accepted.

The legacy worktree was moved intact to
`C:\GUARANTEED OUTCOME\MS-PRESERVE\R6087-20260823-01\legacy-worktree-preserved`.
Its preserved branch is `reconcile/codex-cursor/pre-buy-baseline-v1` at
`f6dfe7587aa02d782e94282d14af8bafff48ded0`; its stale worktree registration
was pruned after the preserving move. The local disposition record
`legacy-worktree-preservation.json` has SHA-256
`FA847BA18A0CD78C28891B908CE1F38AAD718B76116AB81524D0A6B1B130294E`.

## Local preservation and secure inputs

Pre-baseline dirty and untracked material is preserved locally at:

`C:\GUARANTEED OUTCOME\MS-PRESERVE\R6087-20260823-01`

The preservation summary is `preservation-summary.json`. Its current SHA-256
is `C20F1B7F856EB7EED4084E247CC4B4C3F2573847082C2D8AF84C76448E57C99A`.
The reparse-alias resolution manifest SHA-256 is
`4E8DE4FC9074E367D32C0A00CF76390CD33C3D2C4F18BA085347C0A69F53673A`.
The safe-candidate restore manifest SHA-256 is
`DC76EEBCF3F61C6605018E99DD02D4FE9A95C2920F32DDBB4FC65C28149B6B5F`.

Of the 76,625 original untracked move records, 71,581 remain in the primary
vault tree. The 5,044 records intentionally restored to production are also
preserved in `restored-production-snapshot` and bound by
`restored-production-snapshot-manifest.txt` with SHA-256
`EC29912B2FBCA5F248B39A5C5F162A0240BED80AE13B0F0B0E163A2DFCA42E1B`.
That snapshot contains 1,379 additional safe candidates and the 3,665-owner
mandatory registry/coordination restoration union. It has zero overlap with
the blocked secret candidate.

The restored snapshot is the clean current-baseline version, not a claim of
byte-identical reconstruction for every initial moved file. Exactly 1,312 text
owners were mechanically normalized for trailing whitespace or excess final
blank lines before this snapshot; the net size delta is -2,928 bytes. No
product logic was changed by that normalization. The vault retains the
initial move manifests and safe-candidate hashes as the earlier-version audit
record.

One secret-pattern candidate remains only in that local vault. Its path and
content are never committed or emitted. The sealed local blocked-manifest
SHA-256 is
`0692DEB41F8C20F98086C1CA4D35E112AF22B6A5A14547C0602B9EBD410347BB`.

The founder-held Firebase Android configuration remains local and ignored at
`apps/mobile/android/app/google-services.json`. The locked r60.87 checker
verifies its accepted hash without emitting its value. The local diagnostic
signer reference required by that checker remains ignored at its exact r60.86
artifact path. Future APK/AAB work must stop if either local input is absent or
changed; neither may be committed.

Historical raw APK/AAB, screenshot, log and fixture evidence required by old
registry entries remains local and is ignored by exact pre-baseline path. New
ticket evidence after the governance tag must follow the tracked sanitized
evidence and zero-dirt ticket-closure rules.

## Known inherited gate truth

The locked r60.87 Google authentication baseline passes. The independent
approved-UI lock gate retains the pre-existing Screen 01 hash disagreement
registered as
`REG-20260807-216-C10E-LOCKED-UI-PREFLIGHT-FAILED-ON-CLEAN-BRANCH-BASELINE-FILE`.
The r60.87 source owner remains unchanged at its established branch hash; this
governance baseline neither silently restores that source nor re-hashes the
accepted UI reference. Any ticket that must reconcile the Screen 01 reference
requires its own founder-approved locked-reference scope.

## Isolated lanes

Cursor, Codex and integration never mutate the same checkout.

- Cursor UI: `C:\GUARANTEED OUTCOME\MOOLSOCIAL-WORKTREE-CURSOR-<work-id>`
- Codex authentication: `C:\GUARANTEED OUTCOME\MOOLSOCIAL-WORKTREE-CODEX-<work-id>`
- Integration: `C:\GUARANTEED OUTCOME\MOOLSOCIAL-WORKTREE-INTEGRATION-<work-id>`

Each worktree and branch begins from the annotated governance tag
`moolsocial-parallel-production-discipline-20260823`. A worktree is created
only after the founder assigns its exact one-ticket work ID and disjoint owner
claim.

Cursor may modify only its accepted UI/UX and focused-test owners. Codex handles
one selected authentication provider at a time and may not modify unrelated UI.
Integration admits only exact founder/device-approved feature SHAs through
`--no-ff` merge commits. Conflict-time source editing, rebase, squash,
force-push and work on `main` are forbidden.

## Ticket completion boundary

A feature ticket closes only after its implementation commit is founder tested,
the real OPPO requirement passes where applicable, a separate sanitized
evidence-only closure commit binds that accepted commit, the exact remote branch
readback equals closure HEAD, and every managed worktree is clean. Only then may
that agent receive another ticket or integration admit the feature.
