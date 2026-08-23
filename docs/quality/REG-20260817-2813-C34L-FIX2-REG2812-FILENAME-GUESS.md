# REG2813 — C34L FIX2 REG2812 filename guess

Date: 17 August 2026
State: registered read-only reconstruction-path recurrence; zero mutation

## Mistake

After being notified that REG2812 existed, the FIX2 agent guessed its durable
filename as an unrelated leftover-cleanup document. `Get-Content` failed because
the exact file is `REG-20260817-2812-C34L-ATTESTATION-HASH-TABLE-ELLIPSIS.md`.
No mutation or test followed.

## Prevention

Every registry-generation notice must carry exact new document paths, and the
receiver must otherwise resolve numeric IDs with bounded `rg --files` discovery.
Never infer the descriptive suffix from an incident summary.
