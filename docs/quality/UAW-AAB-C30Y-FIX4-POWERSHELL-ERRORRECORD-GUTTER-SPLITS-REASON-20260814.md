# C30Y FIX4 PowerShell ErrorRecord gutter splits reason

- Incident: `REG-20260814-2186-AAB-C30Y-FIX4-POWERSHELL-ERRORRECORD-GUTTER-SPLITS-REASON`
- Diagnostic: `c30y-fix4-candidate-incomplete-pwsh-diagnostic-attempt-04.log`

The retained candidate-context diagnostic has native exit `1`, the exact `C30X successor AAB hard gate rejected:` owner, and the correct incomplete candidate/authority/qualification reason. PowerShell wrapped the final sentence across two rendered error-record lines and prefixed the continuation with `|`. ANSI removal correctly preserved that presentation marker, but a whitespace-only semantic expression could not cross it.

No state, aggregate, source manifest, authority or release count changed. Before retry, the checker must retain the current ANSI-normalized child record, derive a separate classification form that removes only line-leading PowerShell ErrorRecord gutters, and apply the exact reason expression to that semantic form. The corrected attempt must use a new diagnostic path on each host.

Resolution: FIX4 retains the ANSI-normalized record unchanged and derives a separate semantic form by removing only line-leading `|` ErrorRecord gutters. The exact wrapped incomplete-qualification reason then passed under PowerShell 7 and Windows PowerShell with unique attempts 05 and 06.
