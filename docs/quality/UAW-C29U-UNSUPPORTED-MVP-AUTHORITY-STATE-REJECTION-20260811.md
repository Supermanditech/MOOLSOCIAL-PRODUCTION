# C29U unsupported MVP authority-state rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1286-C29U-UNSUPPORTED-MVP-AUTHORITY-STATE-REJECTION`

The first C29U machine state used a descriptive founder-authorization phrase
in `authorization.state`. The gate owner accepts only
`existing_ticket_authority_confirmed` or `founder_acknowledged_mvp_scope` for
an MVP ticket and rejected the state before any cloud mutation.

The correction uses `founder_acknowledged_mvp_scope`. The founder's exact
authorization to deploy the three sealed Dev functions and deny-all rules,
perform the supervised private-upload proof, and later qualify the OPPO
candidate remains recorded in the ticket authority, founder-acceptance text,
execution flags and this task's durable evidence. Production, secret-value
access, build and device mutation remain closed during C29U.
