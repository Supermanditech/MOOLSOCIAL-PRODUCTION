# REG-20260812-1395 — C30J YouTube backend owner path guess rejection

- Phase: C30J reuse/API authority audit
- Failure: The bounded search appended the nonexistent shorthand `functions/src`; repository discovery shows the actual owner is `backend/functions/src`.
- Permanent prevention: Use `rg --files` discovery results as the only backend-owner inputs and never shorten or infer the repository path for a follow-up search.
- Protected state: Read-only failure; no ticket/source/backend/deployment/credential mutation occurred.
