# C30Q required-reading inventory foreach pipe parser rejection

Date: 2026-08-12

## Mistake

A read-only PowerShell command attempted to pipe directly from a `foreach` statement without wrapping the statement as an expression. PowerShell rejected the command with an empty-pipe-element parser error before it inventoried the required document sizes.

## Impact

- No repository, artifact, provider, machine, device, credential, or secret state changed.
- The Play upload was not attempted.

## Permanent prevention

Assign `foreach` output to a named bounded array, then serialize that array. Do not append a pipeline directly after the closing brace of a statement-form `foreach`.
