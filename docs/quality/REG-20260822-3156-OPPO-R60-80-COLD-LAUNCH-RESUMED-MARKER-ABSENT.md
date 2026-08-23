# REG3156 - OPPO r60.80 cold-launch resumed marker absent

## Classification

Registered initial ambiguity resolved by bounded power/focus readback with zero retry.

## Evidence

One bounded launch of the already-installed r60.80 returned `Status=ok`, `LaunchState=COLD`, `TotalTime=1416`, `WaitTime=1449`, a live package process, zero fatal exceptions, zero missing-plugin signals and zero Firebase-initialization-failure signals. The first projection did not find its exact `mResumedActivity` pattern. Without relaunching, one bounded power/focus projection then proved MoolSocial was current focus, focused app, resumed activity and top activity while the display was non-interactive/not ready. Two rendered frames were reported and both were janky; that tiny screen-off startup sample is not treated as steady-state performance or customer-visible qualification.

## Prevention

Do not repeat the launch. Read bounded power, window focus and activity fields together, and never treat a screen-off receipt as customer-visible or performance qualification.
