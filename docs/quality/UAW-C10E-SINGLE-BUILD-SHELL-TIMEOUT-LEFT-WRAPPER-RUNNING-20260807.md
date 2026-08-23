# C10E single-build shell timeout left wrapper running

- Registry: `REG-20260807-232-C10E-SINGLE-BUILD-SHELL-TIMEOUT-LEFT-WRAPPER-RUNNING`
- State: resolved; permanent gate active.

The sole authorized r60.10 build wrapper was launched with an execution timeout
that returned exit 124 after about five seconds. Read-only process inspection
proved that the original wrapper, Flutter build and Gradle child remained
active with the exact sealed version and candidate defines. No second wrapper
or Flutter build was started.

The original process is monitored to its terminal result by PID and reserved
artifact/provenance presence. Future long build wrappers use a yielded
long-running execution cell rather than a short command timeout. A tool timeout
never authorizes a retry while an original build process or result is
unreconciled.
