# C30M deploy-owner range-read truncation rejection

- ID: `REG-20260812-1437-C30M-DEPLOY-OWNER-RANGE-READ-TRUNCATION-REJECTION`
- Date: 2026-08-12
- Scope: local read-only YouTube provider deployment-owner audit
- Result: rejected; no cloud call, source mutation, build, install or device mutation occurred

The attempted 215-line second-half read of `scripts/deploy-youtube-private-dev.ps1`
exceeded the available tool-output context and was truncated. None of that
truncated output is accepted as evidence. C30M retries only with two smaller,
non-overlapping exact ranges (`231..335` and `336..445`) and requires exact
coverage through the known line count before making a provider-only deployment
decision.
