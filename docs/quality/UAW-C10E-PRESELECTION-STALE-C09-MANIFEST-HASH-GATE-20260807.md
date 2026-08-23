# UAW C10E stale predecessor manifest hash gate

- Registry: `REG-20260807-214-C10E-PRESELECTION-RETRIED-BEFORE-SELECTED-TICKET-STATE-RECONCILIATION`
- State: resolved by process gate; no runtime source was written
- Detection: `check-mvp-delivery-discipline-lock.ps1` rejected the attempt because the saved C09 manifest hash no longer matched its assessment.
- Root cause: C10E gate preflight was invoked while `mvp-scope-gate-state.json` still selected the completed C09 predecessor whose ticket document had subsequently changed.
- Durable prevention: before invoking any successor implementation gate, create and verify that successor's robustness/reuse assessment, pin its exact settled manifest SHA-256 and disclosure in the MVP scope state, then invoke the delivery lock with `-RequireTicketSelectionAssessment` and the scope gate with the exact candidate ID.
- Preservation: the fail-closed result occurred before a C10E runtime, build, install or OPPO mutation.
