# C29W stale LASTEXITCODE after PowerShell gate false rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-FRESH-CLIENT-PREPROOF-OPPO-QUALIFICATION-C29W`
- Delivery lock result: explicitly passed

The delivery-lock PowerShell script returned its explicit pass output, but an invalid follow-up `LASTEXITCODE` check read a stale native-process value and falsely threw. No later gates in that composite command ran. Future PowerShell gates run under terminating error semantics and normal return is accepted as success; `LASTEXITCODE` is read only immediately after a native process that owns it. No build, install or provider mutation occurred.
