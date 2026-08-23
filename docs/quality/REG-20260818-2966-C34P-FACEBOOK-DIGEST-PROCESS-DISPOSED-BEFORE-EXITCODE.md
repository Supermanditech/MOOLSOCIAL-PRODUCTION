# REG-20260818-2966 C34P Facebook digest disposed before exit code

Date: 18 August 2026 (IST)
Task: `/root/auth_facebook_native`
State: registered before corrected preflight authorization

## Incident

The Facebook native subagent's mandatory non-emitting raw-byte Git status
digest returned bounded byte, record, SHA-256 and empty-stderr scalars, but
reported `exitCode=null`. Its helper disposed the `System.Diagnostics.Process`
before projecting `ExitCode`, making the otherwise bounded result semantically
incomplete. The subagent stopped before any parser, package operation, source,
test or external action.

The X broker and X mobile owners were also stopped before mutation when the
primary announced the pending registry movement.

## Root cause

Process lifetime was shorter than evidence lifetime: the helper released the
native process before reading every mandatory result field.

## Prevention and retry authority

The corrected digest waits for process completion, copies `ExitCode` into a
ticket-named scalar, and only then disposes the process and streams. It emits
exactly the five allowlisted lines and asserts the exit-code scalar is a
non-null integer. Before resuming, all three subagents refresh regression memory
and pass their coordination gates against the primary-provided new generation;
the Facebook owner additionally rereads this literal incident path.

## Retained evidence

- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
