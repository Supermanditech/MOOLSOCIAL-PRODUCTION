# C30T Windows ripgrep literal-wildcard path error

- Regression: `REG-20260813-1957-C30T-WINDOWS-RG-LITERAL-WILDCARD-PATH-ERROR`
- Date: 2026-08-13
- Scope: read-only backend test discovery; no source mutation resulted.

## Incident

Ripgrep received `backend/functions/src/social/*.test.ts` as a literal Windows
path and rejected it with OS error 123. The grouped output was inadmissible.

## Required prevention

Search the verified directory and select filenames with ripgrep `--glob`.
Every result containing a path error is rejected before retry.

This record creates no build, upload, install, deployment or device authority.
