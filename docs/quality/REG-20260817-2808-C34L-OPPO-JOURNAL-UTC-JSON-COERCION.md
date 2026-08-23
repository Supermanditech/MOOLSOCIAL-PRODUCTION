# REG2808 — C34L OPPO journal UTC JSON coercion

Date: 17 August 2026
State: registered fresh PS7 replay rejection; zero real/external action

## Mistake

After nested source-binding UTC normalization passed, OPPO replay parsed the
transaction journal. PowerShell 7 coerced canonical `preparedUtc` to
`DateTime`; casting it to string before canonical conversion falsely rejected
the valid journal time. Unique fixtures were cleaned and no real or external
action occurred.

## Prevention

Retain the journal's raw JSON text, assert exactly one canonical wire token for
each prepared/committed UTC field, and use those validated tokens or direct
runtime-object normalization for interval ordering. Never cast a coerced JSON
timestamp to string as wire evidence.
