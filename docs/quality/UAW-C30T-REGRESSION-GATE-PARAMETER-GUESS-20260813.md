# C30T regression gate parameter-guess regression

## Observation

The regression-memory check was invoked with a `TicketPath` parameter that is not declared by that script. The failure occurred before the gate executed.

## Root cause

A parameter convention from a different repository gate was applied without reading the exact target script parameter block after compaction.

## Permanent prevention

- Read the bounded `param` block before invoking a repository gate when its signature is not already available in the active context.
- Pass only parameters declared by that exact script.
- Do not infer shared ticket or state parameters across separate gate implementations.
