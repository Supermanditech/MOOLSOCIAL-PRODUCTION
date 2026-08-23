# Autonomous Buy audit dense combined-output truncation

Date: 2026-08-14
Registry ID: `REG-20260814-2110-AUTONOMOUS-BUY-AUDIT-DENSE-COMBINED-OUTPUT-TRUNCATION`

The first discovery attempt combined a full instruction owner, a large scope machine state and a broad Buy/backend search. The returned output was truncated, so no omitted boundary is treated as read.

Before retry, this mistake was registered. Future discovery uses one dense owner per call and narrowly bounded searches whose final requested line is visible. No product or backend source was changed by the rejected command.
