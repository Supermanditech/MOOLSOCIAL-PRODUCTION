# REG3080 — OPPO predecessor package absent before authorized uninstall

- Date: 2026-08-21
- Status: registered before retry

The checksum-bound device command verified one authorized OPPO, then stopped
before uninstall because its raw package-output count was not exactly one. No
uninstall, install or other device mutation occurred. REG3081 later proved the
package was present and registered the false-absence classification.

Prevention: read the live package state immediately before the destructive
branch. If the package is absent, consume no uninstall authority and perform
only the already-authorized single sideload install.
