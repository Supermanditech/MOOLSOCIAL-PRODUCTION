# Buy protected-baseline guessed config-path recurrence

Date: 15 August 2026
Regression: `REG-20260815-2259-BUY-PROTECTED-BASELINE-GUESSED-CONFIG-PATH-RECURRENCE`

The first read-only Buy delta audit read the authoritative gate but also requested a guessed `config/buy-protected-baseline.json`, which does not exist. The gate itself declares the exact protected path as `artifacts/quality/moolsocial-fsc06-shop-products-cell-disposition-20260810-01/BASELINE.json`.

The failed read changed no file. The retry is restricted to the exact gate-declared baseline path; no baseline replacement, reseal or Buy source mutation is authorized.
