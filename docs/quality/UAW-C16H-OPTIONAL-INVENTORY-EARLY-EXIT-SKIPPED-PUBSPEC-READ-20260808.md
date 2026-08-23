# C16H optional inventory early-exit mistake

The first post-host APK inspection normalized an optional `rg` inventory with
`exit 0` before the command's final pubspec read. The inventory and APK state
were read successfully, but the version line was silently skipped.

The retry keeps optional exit validation local and continues execution. The
APK checker, build wrapper and pubspec version are read in explicit bounded
sections before any build authorization changes.
