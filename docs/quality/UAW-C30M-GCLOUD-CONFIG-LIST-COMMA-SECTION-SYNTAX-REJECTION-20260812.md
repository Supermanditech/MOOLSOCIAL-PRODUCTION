# C30M gcloud config-list comma-section syntax rejection

- ID: `REG-20260812-1439-C30M-GCLOUD-CONFIG-LIST-COMMA-SECTION-SYNTAX-REJECTION`
- Date: 2026-08-12
- Scope: read-only Google Cloud CLI context discovery
- Result: command rejected; no cloud mutation, source mutation, build, install or device mutation occurred

The first command passed a comma-delimited property list as the positional
section argument to `gcloud config list`. The installed CLI interpreted it as
one invalid section. C30M retries `gcloud config list` without a positional
section and uses a narrow output projection for `core.account`, `core.project`
and `compute.region`; authentication tokens and credential payloads remain
unread.
