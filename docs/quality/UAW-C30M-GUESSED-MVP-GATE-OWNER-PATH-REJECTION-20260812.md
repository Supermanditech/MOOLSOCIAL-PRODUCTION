# C30M guessed MVP gate-owner path rejection

- ID: `REG-20260812-1447-C30M-GUESSED-MVP-GATE-OWNER-PATH-REJECTION`
- Date: 2026-08-12
- Scope: local read-only deployment-gate composition
- Result: two guessed script paths were absent; no source or cloud mutation occurred

The inventory converted remembered gate names into guessed script filenames.
Windows `rg` rejected both absent paths, so no partial match is accepted. C30M
resolves gate owners from `rg --files scripts` first, then reads only the exact
returned owners before composing a deployment control.
