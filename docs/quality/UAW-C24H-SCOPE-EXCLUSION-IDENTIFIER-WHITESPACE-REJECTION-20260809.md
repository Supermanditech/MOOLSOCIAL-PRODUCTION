# C24H scope exclusion identifier whitespace rejection

Date: 2026-08-09
Regression: `REG-20260809-744-C24H-SCOPE-EXCLUSION-IDENTIFIER-CONTAINED-SPACE`

The first C24H scope-state patch wrote one explicit-exclusion identifier with
an accidental embedded space. Although the JSON parsed and the scope gate did
not reject it, the identifier is not production-grade machine-readable form.
It is rejected before the C24H fingerprint and must be corrected to an
underscore-delimited token.

The exact identifier is now
`no_test_exclusion_business_outcome_weakening_or_skipped_material_gate`.
