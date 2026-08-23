# REG-20260817-2742: C34L transaction-agent regression-memory raw read truncation

## Truthful event

After correcting its Git and handoff reconstruction, the transaction sub-agent
read the complete regression-memory Markdown with one raw `Get-Content` call.
The command exited zero but the 2,716-line output truncated at the tool boundary,
so the visible partial result is not accepted as a complete read. The agent
stopped without retry or mutation.

Before the stop, the agent independently confirmed the exact branch and HEAD,
read the bounded 14:50 and 14:36 handoff sections, and read the ticket plus
REG2729 through REG2737. No candidate state, source seal, cycle, AAB, device,
Google Play, credential, secret, deployment, or external state changed.

## Root cause

The agent applied the bounded-read rule to the handoff but not to the similarly
dense regression-memory owner.

## Prevention

- Measure the current memory line count first.
- Read it in verified, nonoverlapping bounded ranges through the final line.
- Never accept a successful raw read when the tool reports output truncation.

## Candidate consequence

C34L remains selection-only at zero release actions. The truncated memory read
is zero complete reconstruction evidence for that agent turn.
