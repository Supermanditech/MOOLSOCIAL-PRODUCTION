# C29U sealed-ticket completion mutation rejection

- Date: 2026-08-11
- Owner: `config/uaw-personal-mvp-social-dev-backend-deployment-c29u-ticket.json`
- Required sealed SHA-256: `F7C3B42C7648A73C648500DAEACA4A64C6A3EC6DF03F1597818458496A9E7002`

Completion state and deployed revisions were briefly added to the sealed C29U manifest. This was detected before the next gate, deployment or successor activation. A deployment ticket that participates in an exact source hash is immutable after selection.

Only the agent-authored manifest delta is restored with `apply_patch`. The separate C29U completion evidence remains the durable outcome owner, and the C29M successor ticket/scope state carries the transition.
