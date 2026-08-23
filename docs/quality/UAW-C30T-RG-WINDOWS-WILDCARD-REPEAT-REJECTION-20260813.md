# C30T `rg` Windows wildcard repeat rejection — 2026-08-13

A read-only Chat audit repeated the already registered mistake of passing the literal Windows path `apps/mobile/test/chat_*` to `rg`. Windows rejected that path component. Earlier concrete source reads in the same command succeeded and no file changed.

Prevention: use the concrete `apps/mobile/test` directory with `-g 'chat_*.dart'`; never put a wildcard inside a Windows path passed to `rg`.
