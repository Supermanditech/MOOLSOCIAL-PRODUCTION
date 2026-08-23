# REG-20260821-3122 — FIX7 emulator Java not on child PATH

Date: 21 August 2026
State: registered; emulator did not start

## Failure

After correcting the command boundary from REG3121, Firebase Emulator Suite
stopped before Firestore startup because it could not spawn `java -version`.

## Impact

- No emulator or FIX7 test started.
- Firebase shut down cleanly.
- No source, deployment, build, provider, Play, OPPO or private state changed.

## Root cause

The local environment has no global Java command, and the emulator child was
started without the repository-qualified bundled JDK required by permanent
regression memory.

## Prevention

Resolve the exact Flutter-configured Android JDK, verify its `java.exe`, expose
`JAVA_HOME` and prepend its `bin` only for the emulator child, then restore the
parent environment in `finally`. Never install Java or mutate global PATH as a
test workaround.
