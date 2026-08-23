# UAW C33K gcloud Identity Platform command group absent

Date: 2026-08-15

Regression: `REG-20260815-2521-C33K-GCLOUD-IDENTITY-PLATFORM-COMMAND-GROUP-ABSENT`

## Finding

A read-only local capability check invoked `gcloud identity-platform --help`.
The installed Cloud SDK rejected the command because that command group is not
available. No credentials, tokens, configuration values or external resources
were read or changed.

## Resolution rule

- Do not infer a local gcloud command group from a REST resource name.
- Use only documented, locally available CLI commands whose exact behavior is
  proven before execution.
- Never obtain or print an OAuth access token to call the REST API directly.

No Firebase, Hosting, email, build, Play or device action was performed.
