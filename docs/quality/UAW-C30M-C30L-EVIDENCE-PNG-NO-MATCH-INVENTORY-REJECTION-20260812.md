# C30M C30L evidence PNG no-match inventory rejection

- ID: `REG-20260812-1461-C30M-C30L-EVIDENCE-PNG-NO-MATCH-INVENTORY-REJECTION`
- Date: 2026-08-12
- Scope: local read-only OPPO evidence-path discovery
- Result: no match; no source, cloud, build, install or device mutation occurred

The exact C30L device-rejection evidence contains no `.png` or `screenshot`
literal, so fixed-string `rg` returned its normal no-match exit. C30M does not
invent an inherited artifact path. New device evidence uses a ticket-owned
explicit directory after exact-file existence checks; optional text discovery
handles a no-match result without treating it as a command failure.
