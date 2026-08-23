# REG2692 — C34G fixture verification table was clipped

## Outcome

All four fixture owners were written, but table formatting clipped manifest path, hash and file-count verification. The write requires exact readback; the table is not qualification evidence.

## Prevention

Use one labeled scalar object per fixture. Because this registry entry changes the source seal generation, regenerate and rebind a fresh draft before matrix execution.
