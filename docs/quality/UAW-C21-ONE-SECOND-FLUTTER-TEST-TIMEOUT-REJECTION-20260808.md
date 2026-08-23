# C21 one-second Flutter test timeout rejection — 2026-08-08

The corrected C21B command formatted the focused test, then the shell runner killed Flutter after a one-second timeout before any result was produced. The run is rejected and provides no test evidence. Runtime source was not changed by the command.

Focused Flutter tests use a normal bounded timeout long enough for tool startup and compilation. Early yielding, when needed, is handled by the orchestration wait mechanism rather than by terminating the shell process.
