# REG-20260822-3204 — Build monitor poll yield session ID not preserved

## Incident

A read-only build-state poll slept for the same duration as its tool yield
boundary and returned no projected output while the wrapper omitted any
returned session identifier.

## Impact

- Active APK build altered or interrupted: `false`
- Additional build attempts: `0`
- OPPO actions: `0`
- Private/provider actions: `0`

## Root cause

The poll used a 30-second sleep with a 30-second tool yield and projected only
stdout instead of also preserving `session_id` when the nested command yielded.

## Permanent prevention

Use a sleep shorter than the tool yield and always project either final output
and exit code or the returned session identifier. Register an ambiguous poll
before any corrected poll.
