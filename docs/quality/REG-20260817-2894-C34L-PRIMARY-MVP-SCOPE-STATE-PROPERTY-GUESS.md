# REG2894 — C34L primary MVP scope-state property guess

- Status: registered read-only planning projection mistake.
- Mistake: the primary projected guessed top-level `activeTicketId`, `ticketPath`, `ticketSha256`, `robustnessAndReuseAssessmentPath`, and `executionAuthorized` properties from `mvp-scope-gate-state.json`; most returned blank because the live schema uses different names/nesting.
- Root cause: the state schema was inferred rather than inspected before projection.
- Prevention: enumerate exact top-level property names first, then read only the live selected-ticket/assessment/authority structure; never treat blank guessed projections as evidence.
- Impact: read-only; no ticket selection, login, provider, device, private, release, or external action.
