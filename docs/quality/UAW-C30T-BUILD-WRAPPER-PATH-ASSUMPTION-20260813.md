# C30T build wrapper path assumption — 2026-08-13

## Outcome

A pre-authorization read-only exact-value search included one inferred build
wrapper path that does not exist. The canonical C30T gate and founder launcher
still returned their required state matches, but the overall search command
reported the missing third path. No mutation or build occurred.

## Root cause and prevention

The search mixed known literal owners with a conceptually named script path.
Future searches use only resolved canonical owners. Any additional wrapper path
must be copied from the founder launcher or another executable repository owner
before it is included.

Because this registry evidence is source-sealed, both no-AAB qualification
cycles must be repeated before build authority can be activated.
