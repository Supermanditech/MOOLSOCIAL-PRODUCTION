# C29U parallel shell metadata empty-wrapper rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1293-C29U-PARALLEL-SHELL-METADATA-EMPTY-WRAPPER-REJECTION`

Five Secret Manager `describe` commands were composed in a parallel shell-tool
wrapper. The wrapper rendered `{}` for each result rather than command stdout,
so the complete probe was rejected as evidence. No secret value command was
issued and no cloud state was changed.

The retry uses one direct bounded gcloud metadata command at a time. It may
prove secret name, replication and enabled-version state but must never invoke
`secrets versions access` or otherwise read a payload.
