# C30L deployment evidence broad-search truncation

- Scope: local read-only deployment-preparation audit.
- Rejection: a broad evidence search matched a generated Flutter timeline payload and truncated before the deployment history was completely evaluated.
- Root cause: App Check, IAM and revision questions were combined across broad artifact roots.
- Prevention: inspect exact deployment records and bounded registry windows separately, excluding generated performance evidence.
- Runtime impact: none. No cloud write, deployment, build, install, or device mutation occurred.
