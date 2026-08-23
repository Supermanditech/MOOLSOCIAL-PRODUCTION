# C30Y C30X expected-rejection label mismatch

- Incident: `REG-20260814-2183-AAB-C30Y-C30X-EXPECTED-REJECTION-LABEL-MISMATCH`
- Failed evidence: `c30y-post-fix3-cycle-01-static.log`, `c30y-post-fix3-cycle-01-static.exit.txt`
- Disposition: non-qualifying cycle attempt; preserved

The first post-FIX3 cycle-1 static run passed every positive source and dual-host gate. Its expected unauthorized C30X build probe also exited nonzero and emitted the correct fail-closed reason: candidate identity, authority or all-regression source qualification is incomplete. The orchestration nevertheless wrote exit `1` because its classifier omitted the word `hard` from the exact C30X rejection prefix.

No Flutter suite, analyzer, backend test, Hosting test, build, upload or device action followed. Before retry, the regression must be selected through the MVP scope rule and implemented as a repository-owned negative classifier that binds the exact C30X owner prefix and incomplete-qualification reason. The preserved failed paths cannot be overwritten or reused; a corrected run must use a new attempt-specific evidence name.

Resolution: FIX4 now owns the exact `hard gate rejected` prefix and exact context reason, retains unique child diagnostics, and proved unchanged state, aggregate, manifest, authority and `0/0/0` actions. Its FIX4-scope and C30Y incomplete-qualification contexts both passed on PowerShell 7 and Windows PowerShell. The failed static attempt remains preserved and excluded from qualification.
