# C30Y FIX4 active scope precedes incomplete-authority rejection

- Incident: `REG-20260814-2185-AAB-C30Y-FIX4-ACTIVE-SCOPE-PRECEDES-INCOMPLETE-AUTHORITY-REJECTION`
- Diagnostic: `c30y-fix4-child-c30x-diagnostic-attempt-01.log`

The retained child diagnostic records native exit `1` and the exact normalized C30X reason: `C30X preparation or exact C30Y candidate scope changed.` This is correct because FIX4, not C30Y, was the selected MVP ticket. C30X validates its common scope before the phase-specific incomplete candidate/authority/qualification assertion, so the original classifier could not truthfully reach its target in that context.

No state, aggregate, source manifest, authority or release count changed. Before retry, the checker must expose an exact context parameter. The implementation context must require the FIX4-scope rejection. After the selected scope returns to C30Y, the qualification context must require the incomplete candidate/authority/qualification rejection. Each context needs a unique retained diagnostic file and before/after non-mutation proof on both supported PowerShell hosts.

Resolution: `ExpectedContext` now binds `fix4_scope` only while FIX4 is selected and `candidate_incomplete` only while C30Y is selected. Both exact contexts passed on PowerShell 7 and Windows PowerShell, each with unique diagnostic evidence and unchanged state/aggregate/manifest hashes, false build authority and `0/0/0` release actions.
