# UAW C30W active-handoff combined-window output truncation — 2026-08-14

## Scope

This record covers a read-only required-owner review during the 14 August C30W overnight continuation. It did not mutate release source, manifests, build artifacts, Play state, the OPPO device, services, or secrets.

## Mistake

Two dense 200-line windows from `docs/quality/ACTIVE-CODEX-HANDOFF.md` were requested in one tool call. Their combined output exceeded the available response context and was truncated. The attempted lines are therefore zero evidence and were not admitted as a completed owner read.

## Impact

- No repository or external state was changed by the rejected read.
- No conclusion was based on the truncated output.
- The affected handoff range remains unread until each window is returned completely and its final requested line is present.

## Root cause

The command respected the per-window 200-line limit but failed to account for the aggregate volume of two dense windows in one returned tool result.

## Prevention and retry rule

- Request only one dense owner-document window per tool call.
- Keep each request at 200 lines or fewer.
- Verify that the returned first and last line numbers match the requested range before crediting the read.
- Treat any truncation marker or missing final requested line as zero evidence and do not advance the read cursor.

## Resolution

Registered before retry as `REG-20260814-2103-C30W-ACTIVE-HANDOFF-COMBINED-WINDOW-OUTPUT-TRUNCATION`. The unread range will be retried as separate bounded calls.
