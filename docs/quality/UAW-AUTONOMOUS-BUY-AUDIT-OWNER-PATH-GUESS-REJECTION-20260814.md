# Autonomous Buy audit owner-path guess rejection

Date: 2026-08-14
Registry ID: `REG-20260814-2109-AUTONOMOUS-BUY-AUDIT-OWNER-PATH-GUESS-REJECTION`

The first bounded discovery attempt guessed locations for the pre-ticket checkpoint and active handoff owners. Both guessed locations were wrong, and the combined command exited nonzero. Its partial output is not accepted as evidence.

Before retry, this mistake was registered. The retry must enumerate paths with `rg --files`, copy returned paths literally, and read only exact owners. No application or backend source was changed by the rejected command.
