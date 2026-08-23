# Full Chat compact test progress output truncation

Date: 2026-08-14
Registry ID: `REG-20260814-2122-FULL-CHAT-COMPACT-TEST-PROGRESS-OUTPUT-TRUNCATION`

The first full-Chat baseline invoked Flutter's compact reporter directly. The runner exited zero, but carriage-return progress frames expanded into a truncated tool result. That output is not accepted as baseline or qualification evidence.

Every corrected Chat test invocation must capture output in memory and emit only its final summary on success, with a bounded tail on failure. No Chat source, backend, reference or machine state was changed by this reporting mistake.
