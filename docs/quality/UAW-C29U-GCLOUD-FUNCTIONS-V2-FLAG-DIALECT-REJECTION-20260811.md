# C29U gcloud Functions v2 flag-dialect rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1292-C29U-GCLOUD-FUNCTIONS-V2-FLAG-DIALECT-REJECTION`

The first bounded deployed-Functions inventory passed `--gen2` to
`gcloud functions list`. The installed SDK rejected that spelling and directed
the caller to `--v2`; no metadata or cloud state changed.

The retry uses the locally accepted `--v2` flag and still verifies the returned
function environment explicitly. A syntax rejection is not evidence that a
function is absent.
