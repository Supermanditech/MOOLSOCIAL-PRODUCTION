# C30O browser diagnostic Promise.all nonzero abort rejection

- Date: 2026-08-12
- Scope: read-only Chrome browser-extension connection diagnostics
- Result: rejected diagnostic aggregation; no external or product state changed

## Mistake

Four packaged browser diagnostics were launched with `Promise.all`. The expected nonzero result from `check-extension-installed.js` rejected the aggregate and prevented the other diagnostic results from being retained in the response.

## Root cause

Expected diagnostic exit statuses were treated as exceptional inside a fail-fast aggregate instead of being isolated per command.

## Permanent prevention

Do not rerun the already-conclusive extension check. If other packaged diagnostics are needed, execute only the remaining checks independently with per-command error isolation so one expected nonzero result cannot discard the others.

## Conclusive retained fact

The ChatGPT Chrome extension is not installed in the selected Chrome profile. No extension installation, browser change, Play mutation, credential access, or external write occurred.
