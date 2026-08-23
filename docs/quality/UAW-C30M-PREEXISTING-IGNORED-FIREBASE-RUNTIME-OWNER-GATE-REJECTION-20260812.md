# C30M pre-existing ignored Firebase runtime owner-gate rejection

- ID: `REG-20260812-1452-C30M-PREEXISTING-IGNORED-FIREBASE-RUNTIME-OWNER-GATE-REJECTION`
- Date: 2026-08-12
- Scope: local C30M provider-only package qualification
- Result: failed closed before backend verification or cloud action

The package gate found the ignored
`backend/functions/.env.moolsocial-dev-503018` file already present before C30M
materialization. Its ownership is not inferred and the file is not overwritten
or deleted. C30M records only path metadata/hash and compares it to the
deterministic accepted PublicDataReview materialization without printing
contents or credentials; any mismatch remains a founder-visible block.
