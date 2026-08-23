# REG2867 — C34L primary registry short-ID and property guess

- Status: registered read-only diagnostic mistake.
- Scope: registry/tooling/failure handling only.
- Mistake: a registry projection searched for shortened `REG2865` instead of the exact durable ID and guessed nonexistent top-level `count` and `hash` properties, producing a false zero match and unusable count/hash values.
- Root cause: summarized labels were substituted for the parsed registry's exact schema and full entry identity.
- Prevention: parse `entries`, compare the exact full `id`, use `entries.Count`, and compute the file SHA separately; inspect the last exact entry when preparing registration.
- Repository/external impact: the diagnostic was read-only; no release or external action.
