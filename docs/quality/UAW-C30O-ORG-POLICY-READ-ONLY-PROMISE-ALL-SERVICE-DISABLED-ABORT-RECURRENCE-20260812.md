# C30O organization-policy read-only Promise.all service-disabled abort recurrence

Date: 2026-08-12

## Observed mistake

Four read-only `gcloud` diagnostics were launched in one fail-fast aggregate. The Organization Policy API is disabled on the Dev project, so an expected nonzero result rejected the aggregate and prevented retention of the other independent outputs.

## Root cause

The diagnostics repeated the already-registered pattern of treating an expected per-command diagnostic failure as exceptional inside `Promise.all`.

## Prevention

- Do not repeat the Organization Policy API command and do not enable the API for this diagnosis.
- Run the remaining project, account, and legacy-policy diagnostics independently with per-command error isolation.
- Treat service-disabled output as a bounded unknown for CLI inspection, not as authority to mutate service state.

## Retained evidence

The tool result records `SERVICE_DISABLED` for `orgpolicy.googleapis.com`, authentication as `hello@moolsocial.com`, and the default negative response to the enable prompt. No API or policy mutation occurred.
