# C30T Cloud Run read authentication diagnosis correction

Date: 2026-08-13

The first Cloud Run revision read suppressed stderr and was initially attributed to an assumed region. A bounded retry retaining the native diagnostic showed the immediate blocker is expired local `gcloud` authentication: the CLI requires interactive reauthentication and cannot prompt in the non-interactive run.

No provider state changed. Interactive login, password and MFA remain founder-visible steps and were not attempted. Permanent prevention: never suppress provider-read stderr on failure and do not assign a cause before retaining the exact diagnostic.
