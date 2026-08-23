# REG2804 — C34L attestation UTC JSON coercion

Date: 17 August 2026
State: registered second PS7 fixture rejection; zero real or external action

## Mistake

The second fresh PS7 source-attestation checker reached the source writer but
rejected canonical `producedUtc` because `ConvertFrom-Json` coerced the wire
string to `DateTime`; casting that value back to string lost the required
`.fffZ` spelling. Fixture cleanup ran and no real or external action occurred.

## Prevention

Accept string, `DateTime`, or `DateTimeOffset` runtime shapes, normalize the
semantic instant to invariant `.fffZ`, and independently assert the exact raw
JSON timestamp token spelling and cardinality before accepting the retained
attestation.
