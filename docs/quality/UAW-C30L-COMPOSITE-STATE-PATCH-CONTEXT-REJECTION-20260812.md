# C30L composite state-patch context rejection

- ID: `REG-20260812-1431-C30L-COMPOSITE-STATE-PATCH-CONTEXT-REJECTION`
- Date: 2026-08-12
- Scope: local durable ticket and evidence writes
- Result: entire composite patch rejected; no partial mutation occurred

The first disposition patch spanned unrelated durable owners and failed on an MVP authorization context. The retry is split by owner with exact bounded context and JSON validation after each state file.
