# Post-YouTube audit C28E r60.27 machine-state hash rejection

Date: 15 August 2026
Registry: `REG-20260815-2248-POST-YOUTUBE-AUDIT-C28E-R60-27-MACHINE-STATE-HASH-REJECTION`

After C32I source qualification, the existing C28E qualifier was invoked with
`-GatePreflightOnly`. It stopped at the first host gate with:

`C28E host gate rejected: r60.27 machine state changed`

No downstream C28E gate, Flutter test, device action or qualification evidence
ran. No repository file was changed by the rejected preflight. The protected
r60.27 file and its expected hash must be resolved from exact literal contract
fields and retained evidence before deciding whether the protected state was
mutated or the historical assertion is stale. No correction or retry is
authorized by this initial record.
