# REG2701 — C34H browser composition marker wrapped across Markdown lines

## Outcome

The truthful document says no new C34H browser action occurred, but ordinary Markdown wrapping splits “No” and “new.” An exact `Contains` assertion falsely rejected the preprompt fixture. No source seal, build or external action occurred.

## Prevention

The gate uses a whitespace-tolerant semantic regex for this marker. The evidence wording remains unchanged and the complete phase matrix is replayed before sealing.
