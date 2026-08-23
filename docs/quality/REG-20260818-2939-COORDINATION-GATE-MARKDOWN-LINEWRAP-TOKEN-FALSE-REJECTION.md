# REG2939 — Coordination gate Markdown line-wrap token false rejection

## Observed event

After REG2938 added machine checks for bounded status instructions, the primary coordination gate rejected `AGENTS.md` as missing `do **not** emit full git status`. The required words were present but split by Markdown line wrapping, so literal `Contains` did not match.

## Impact

- The coordination gate exited 1; no subagent was resumed.
- No source-map, runtime, provider, device, private, build, or external action followed.

## Root cause

The gate used literal whitespace-sensitive prose tokens for a Markdown owner that permits semantic line wrapping.

## Mandatory prevention

Normalize Markdown whitespace (`\s+` to one space) before prose-token checks, or check stable code literals/headings that cannot wrap. Keep exact code-token checks for `git status --porcelain=v1 -z`.
