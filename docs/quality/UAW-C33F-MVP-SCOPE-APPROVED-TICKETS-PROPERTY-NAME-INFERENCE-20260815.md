# UAW C33F MVP scope property-name inference correction

Date: 2026-08-15

## Registered mistake

A bounded search assumed the current MVP scope state used an
`approvedTickets` property. The property is absent and the search returned no
match.

## Safe correction

- Register before retry.
- Discover root property names from the parsed current state.
- Access only the exact discovered collection with named-field projections.
- Do not broadly serialize nested historical scope state.
