# REG-20260821-3123 — Data Connect emulator exit-zero ECONNRESET shutdown

Date: 21 August 2026
State: registered; emulator result not accepted

## Failure

The Data Connect `emulators:exec` command reported script success and native
exit 0, but bounded error-line inspection showed Postgres `ECONNRESET` and an
error stopping the Data Connect emulator.

## Impact

- The run is not accepted as clean Data Connect schema or mutation evidence.
- No source, cloud database, deployment, build, provider, Play or OPPO state
  changed.

## Root cause

The wrapper treated script exit and Firebase process exit as sufficient while
ignoring emulator-owned shutdown errors.

## Prevention

Data Connect qualification requires zero emulator error lines in addition to
script success and exit 0. Do not repeat this unstable emulator attempt; use a
direct CLI schema validation/diff command with no apply/deploy action, or keep
Data Connect qualification explicitly pending if that surface is unavailable.
