# C30N MVP state-vocabulary guess rejection

- ID: `REG-20260812-1465-C30N-MVP-STATE-VOCABULARY-GUESS-REJECTION`
- Date: 2026-08-12
- Scope: local C30N successor selection state
- Result: MVP scope gate rejected before any runtime, build, install, external write or device action

C30N wrote a descriptive `ticket_disclosed_authority_pending` value without
first resolving the gate-owned state vocabulary. The delivery selection
assessment passed, but the MVP state gate treated the unknown value as closed
and required the next classification state. C30N reads the exact allowed
transition literals from the gate and stores descriptive nuance in the
authorization and ticket fields instead of inventing a machine-state value.
