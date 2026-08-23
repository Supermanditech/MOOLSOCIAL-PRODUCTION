# UAW C33K MVP authorization-state enum mismatch

Date: 2026-08-15

Regression: `REG-20260815-2518-C33K-MVP-AUTHORIZATION-STATE-ENUM-MISMATCH`

## Finding

The first C33K execution-authority replay stopped before any external write.
The scope record used the descriptive value
`founder_authorized_exact_required_actions`, while the existing MVP gate accepts
only `existing_ticket_authority_confirmed` or
`founder_acknowledged_mvp_scope` for an MVP-classified ticket.

The separate `founderAcceptance` field already preserves the exact 15 August
authorization wording. No Firebase setting, email, deployment, build, Play or
device state changed during the failed gate.

## Resolution rule

- Machine enum fields use only values enumerated by their existing checker.
- Exact founder language stays in the adjacent evidence field and ticket.
- Retry is blocked until this regression is registered and the regression
  memory gate passes.

No broader authority is created by this correction.
