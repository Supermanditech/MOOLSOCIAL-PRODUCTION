# C30D MVP-state formatting-context patch rejection

- Regression: `REG-20260811-1370-C30D-MVP-STATE-FORMATTING-CONTEXT-PATCH-REJECTION`
- Date: 2026-08-11
- Observation: the initial `mvp-scope-gate-state.json` patch expected single-line arrays while the live file uses multi-line formatting.
- Result: `apply_patch` rejected the context and made no state-file change.
- Prevention: patch exact bounded live sections, then parse the JSON and validate the ticket hash before running MVP gates.
