# REG-20260812-1389 — C30I unsupported MVP implementation disposition rejection

- Phase: C30I pre-implementation scope gate
- Failure: The MVP delivery lock rejected the new token `shared_owner_extension` because it is not in the checkpoint's supported implementation-disposition vocabulary.
- Permanent prevention: Read the locked allowed-value set before authoring or updating a machine ticket and use the narrowest exact supported token; never invent a semantically similar disposition label.
- Protected state: The gate stopped before C30I source/test implementation, build, install or deployment.
