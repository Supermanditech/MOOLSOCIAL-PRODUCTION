# C30O Play Internal Get started occluded semantic-click no-op rejection — 2026-08-12

## Disposition

Rejected read-only navigation no-op. The page remained on Test and release and no track state changed.

## Mistake

The Internal testing Get started semantic click returned success while Codex visibly occluded most of Chrome, and the page did not navigate.

## Root cause

The indexed click was dispatched against an underlying page whose effective hit target was obscured by the foreground Codex window.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Do not repeat the occluded semantic click.
- Ask the founder to foreground Chrome and click only Internal testing **Get started**.
- Refresh and verify the resulting title before any track mutation.
