# C30N closed-state active-selection gate rejection

- ID: `REG-20260812-1469-C30N-CLOSED-STATE-ACTIVE-SELECTION-GATE-REJECTION`
- Date: 2026-08-12
- Scope: local C30N delivery-lock validation
- Result: machine gate rejected; no runtime, build, install, cloud or device mutation occurred

After correcting C30N to the exact authority-pending closed state, the audit
invoked the delivery lock with `-RequireTicketSelectionAssessment`. That switch
requires the selected assessment ID to equal an active ticket ID, while the MVP
scope gate requires an authority-pending closed state to have no active ticket.
The invocation is rejected. Pending scope uses the delivery lock without the
active-execution switch and then the closed MVP scope gate; the switch is
reserved for a separately authorized active ticket.
