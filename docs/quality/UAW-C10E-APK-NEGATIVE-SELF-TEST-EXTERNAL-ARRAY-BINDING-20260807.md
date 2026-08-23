# C10E APK negative self-test external array binding

- Registry: `REG-20260807-231-C10E-APK-NEGATIVE-SELF-TEST-EXTERNAL-ARRAY-BINDING`
- State: resolved; permanent gate active.

The first planned wrong-fingerprint self-test called the PowerShell checker
through an external `pwsh -File` process while supplying a `string[]` runtime
define array. External argument flattening made the second define positional,
so parameter binding failed before the intended machine-state assertion. The
harness then reached its own unexpected-pass guard. No APK build or OPPO
mutation occurred.

PowerShell checker self-tests now invoke the script in-process with `&`, which
preserves exact `string[]` binding and makes caught terminating errors
observable. External `pwsh -File` is retained for the actual build wrapper,
whose scalar parameters are unambiguous.
