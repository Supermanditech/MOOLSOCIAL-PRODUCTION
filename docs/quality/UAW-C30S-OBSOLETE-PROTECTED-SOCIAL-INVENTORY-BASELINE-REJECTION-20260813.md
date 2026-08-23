# C30S obsolete protected Social inventory baseline rejection

Date: 2026-08-13

After all 52 affected tests, release config and dependencies passed, the legacy
C25F Social seal rejected because it expects 178 files while the current
founder-owned dirty tree contains 201. Replacing that historical baseline is
not authorized by C30S and would mutate a founder-controlled global seal.

The rejection is preserved. C30S instead requires the accepted C30Q source
baseline, its own exact source fingerprint, the 52-file affected suite,
Android player gate and personal-action projection twice. A future global
baseline replacement requires separate founder authority.
