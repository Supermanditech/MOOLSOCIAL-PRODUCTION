# C30O Gmail full compliance-thread MIME truncation rejection — 2026-08-12

## Disposition

Rejected as reviewer-draft evidence. Gmail remained read-only; no draft, reply, send, label or mailbox mutation occurred.

## Mistake

The first Gmail read requested the complete long-running compliance thread with full MIME payloads. The connector response exceeded the bounded transcript and was truncated.

## Root cause

Historical messages and transport headers were retrieved even though the current task only required the exact 2026-08-06 request and immediately preceding founder response.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Read only the exact latest message and, if needed, the exact immediately preceding sent message.
- Use the smallest message representation that preserves the text body and essential headers.
- Never use the truncated thread response as draft evidence.
