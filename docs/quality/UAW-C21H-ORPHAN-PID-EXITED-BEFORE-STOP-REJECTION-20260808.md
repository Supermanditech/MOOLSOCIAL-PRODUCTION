# C21H orphan PID exited before stop — 2026-08-08

The verified Flutter-test orphan PID 9536 exited naturally between preflight observation and cleanup. The stop command refused because the target was no longer present; no process was killed.

REG-20260808-500 requires fresh command-line enumeration, an explicit already-gone disposition, and a separate zero-active-build/test assertion. No build or device mutation occurred.
