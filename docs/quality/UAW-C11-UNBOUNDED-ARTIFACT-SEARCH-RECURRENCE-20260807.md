# C11 unbounded artifact-search recurrence

Date: 2026-08-07

Regression ID:
`REG-20260807-241-C11-UNBOUNDED-ARTIFACT-SEARCH-RECURRENCE`

During C11 protected-gate reconciliation, a diagnostic fixed-string search
included the complete retained `artifacts/quality` tree. It timed out before
producing a usable result, repeating the already registered unbounded-artifact
search class.

The recurrence happened because the diagnostic command grouped documentation,
configuration and the evidence archive without first proving that the archive
was necessary. The corrected lookup searches only `docs/quality` and `config`;
an exact evidence directory may be added later only when a known path requires
it.

Permanent prevention: routine authority and regression discovery starts in
known documentation/configuration owners. Large retained artifact trees are
never a default search root and are searched only by exact candidate directory
or narrow filename inventory.
