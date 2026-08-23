# C30T regression evidence path-guess recurrence

- Date: 2026-08-13
- Repository: `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Scope: read-only regression-memory inspection

A diagnostic guessed that a prior evidence filename included its numeric registry ID. The real filename did not, and `Get-Content` failed without reading any unrelated path or changing state.

This repeated the path-guessing class registered immediately beforehand. All subsequent evidence reads must use exact paths returned by `rg --files`; filenames must not be synthesized from registry IDs.
