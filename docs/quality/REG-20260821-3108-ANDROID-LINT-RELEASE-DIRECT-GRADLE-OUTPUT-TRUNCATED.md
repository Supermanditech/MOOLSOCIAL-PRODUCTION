# REG-20260821-3108 — Android lintRelease direct Gradle output truncated

Date: 21 August 2026
State: registered; direct transcript not accepted as final lint evidence

## Failure

The first `:app:lintRelease` replay after REG3104 streamed Gradle task output
directly to the tool channel. One running-session result truncated 11,717
tokens before the terminal poll returned `BUILD SUCCESSFUL` and exit code 0.

## Impact

- The release lint report was produced and the native process exited 0.
- No APK, install, provider, Play, OPPO or private authentication action ran.
- The direct transcript is diagnostic only and is not counted as sealed lint
  qualification evidence.

## Root cause

The authoritative Gradle lint task was invoked with ordinary console output
instead of capturing stdout/stderr separately and emitting a bounded terminal
summary.

## Prevention

Replay the exact read-only lint task through in-memory process capture with
separate stdout/stderr, retain the native exit code immediately, and emit only
bounded success/task/report/error-warning counts plus the lint report byte
length and SHA-256. Never stream the full Gradle task graph as acceptance
evidence.
