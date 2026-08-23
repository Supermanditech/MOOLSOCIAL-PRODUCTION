# REG2815 — C34L FIX2 sanitized-path static token linebreak

Date: 17 August 2026
State: registered first PS7 lifecycle fixture failure; zero real/external action

## Mistake

The first PS7 FIX2 lifecycle fixture rejected its transition-owner static
assertion for the required sanitized path. The implementation contained the
validation, but the checker searched for one contiguous token while the
PowerShell expression and `'/console/app/internal-testing'` literal were split
across lines. No retry, later mutation, or external action followed.

## Prevention

Assert durable semantic anchors separately: the exact `sanitizedPath` property
access, the ordinal comparison operator, and the exact route literal. Behavioral
negatives remain the authority for wrong-host/path acceptance; static checks
must not depend on whitespace or line wrapping.
