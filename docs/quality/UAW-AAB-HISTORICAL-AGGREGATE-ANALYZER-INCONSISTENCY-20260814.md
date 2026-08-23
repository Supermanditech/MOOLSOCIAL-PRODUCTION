# AAB historical aggregate analyzer inconsistency

Date: 14 August 2026
Scope: successor AAB preparation audit

The preserved failed r60.47 candidate state records
`sourceQualification.analyzerPassed=true`, while its aggregate records
`sourceQualification.wholeMobileAnalyzerClean=false`. Both historical files
remain immutable, and neither is accepted as successor readiness evidence.

C30X requires fresh successor analyzer evidence and a fresh two-cycle source
qualification whose state and aggregate agree. The current independent audit
did run clean, but the global approved-UI lock remains red, so build readiness
is still false.
