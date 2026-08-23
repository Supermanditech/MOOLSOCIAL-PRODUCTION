# C30O Play Create email list screenshot Codex-occlusion rejection

- Date: 2026-08-12
- Scope: screenshot-bound fallback for the Internal-testing tester-list control
- Result: rejected before input

## Mistake

A screenshot-only observation was requested for the exact Chrome window, but the captured state showed the Codex application visibly covering the Play page. The rendered `Create email list` control was therefore not safely available for a screenshot-bound coordinate action.

## Root cause

After the founder returned control to the task, the Codex application regained foreground ownership while the target Chrome page remained behind it.

## Permanent prevention

Do not click using this screenshot or reuse its screenshot ID/coordinates. Raise only the already-selected Chrome target window as a standalone action, acquire a fresh screenshot afterward, and proceed only if the target control is unobscured. Never automate or click the Codex application.

## Safety outcome

No screenshot coordinate input, Play mutation, tester list, tester access, credential action, or external write occurred.
