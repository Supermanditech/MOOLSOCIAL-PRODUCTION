# C29W predecessor ticket source-gate replay rejection

- Date: 2026-08-11
- Active ticket: `UAW-PERSONAL-MVP-SOCIAL-FRESH-CLIENT-PREPROOF-OPPO-QUALIFICATION-C29W`
- Result: C29N rejected before later predecessor gates ran

The durable C29N-C29T source gates are ticket-bound. C29N correctly rejected when invoked while C29W was active, and no later predecessor gate ran. Those gates are not retried and the active ticket is not changed to satisfy them. C29W reuses their immutable host evidence and produces fresh current-source format, analysis and focused-test evidence under its own scope. No build, install or provider mutation occurred.
