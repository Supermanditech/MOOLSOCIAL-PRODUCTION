# REG-20260817-2738: C34L integration-audit foreach pipeline recurrence

## Truthful event

While measuring required reconstruction owners, the integration-audit
sub-agent used a statement-form `foreach` directly before
`Format-Table`. PowerShell rejected the read-only diagnostic with
`An empty pipe element is not allowed`, and the agent stopped without retry.

No assigned owner, candidate state, source seal, cycle, AAB, device, Google
Play, credential, secret, deployment, or external state changed.

## Root cause

The sub-agent repeated the REG2731 parser pattern instead of materializing the
loop results into a named collection before formatting.

## Prevention

- Assign loop output to a ticket-specific array before any pipeline.
- Keep file measurement and presentation as separate statements.
- Parser-check the bounded diagnostic before using its output for required
  reconstruction.

## Candidate consequence

C34L remains selection-only at zero release actions. The rejected read-only
diagnostic is zero owner-measurement evidence for that agent turn.
