# REG2895 — C34L primary MVP scope deep-projection truncation

- Status: registered read-only planning reconstruction failure.
- Mistake: after discovering the live state schema, the primary serialized the complete nested ticket/checkpoint/preselection/authorization/execution objects at depth 8. The result expanded to tens of thousands of tokens and truncated.
- Root cause: broad historical preselection objects were included when only the current ticket, authorization, and execution scalars were needed.
- Prevention: project current `ticket.id`, current classification/exclusions, `authorization`, and exact `execution` scalar fields independently; never serialize the full historical `preTicketSelectionCheckpoint` object.
- Impact: read-only; no ticket replacement, login, provider, device, private, release, or external action.
