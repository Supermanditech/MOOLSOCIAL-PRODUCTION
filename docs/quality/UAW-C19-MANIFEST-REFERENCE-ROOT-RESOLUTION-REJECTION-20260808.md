# C19 manifest reference-root resolution rejection

Date: 8 August 2026

Ticket: `UAW-PERSONAL-MVP-SCREEN03-PROFILE-PROVENANCE-TEST-LOCK-RECONCILIATION-FIX1-C19`

State: **REJECTED BEFORE RETRY**

The first focused C19 gate resolved the manifest's `interactionContract` and
`productionAcceptance` values from the repository root. Approved-reference
manifest links are intentionally relative to `approved-references`, so the gate
looked for a nonexistent top-level `screens` directory and rejected a package
that was present at the correct protected location.

The failure was registered as REG-385 before correction. Focused reference
gates must distinguish repository-relative production-owner paths from
approved-reference-root-relative manifest links and prove containment for both.
