# C30T gcloud logging filter PowerShell escaping rejection

- Date: 2026-08-13
- Project: `moolsocial-dev-503018`
- Intended revisions: `youtubeprovider-00036-qer`, `moolsocialcontent-00003-juw`
- Scope: read-only status telemetry only

The first Cloud Logging query used Bash-style backslash escaping around the UTC timestamp inside a PowerShell string. `gcloud logging read` interpreted the timestamp as an extra malformed argument and rejected both queries. No log data, request payload, URL, header, token, nonce, attestation or private verdict was returned or accessed.

The retry must pass one preconstructed filter string per provider and keep the output projection strictly to timestamp, revision name, HTTP request method, HTTP status and severity.
