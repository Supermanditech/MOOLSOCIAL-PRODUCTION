# C11 brand gate stale Buy accessibility search heights

- Regression: `REG-20260807-261-C11-BRAND-GATE-STALE-BUY-ACCESSIBILITY-SEARCH-HEIGHTS`
- Date: 2026-08-07 IST

## Observation

The final gate set reached brand integrity after all navigation gates passed.
Brand integrity still required the pre-fix 150-pixel accessibility search
control and 162-pixel band, while the compact overflow correction now uses a
162-pixel control and 174-pixel band.

## Permanent correction

The authorized accessibility fitment values are synchronized across the
runtime, `config/brand-integrity.json` and the brand checker. The exact
320x568/140-percent Buy search journey remains required alongside the static
contract, so a constant-only update cannot conceal a render regression.
