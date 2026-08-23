# C19 non-specific manifest status patch rejection

Date: 8 August 2026

Ticket: `UAW-PERSONAL-MVP-SCREEN03-PROFILE-PROVENANCE-TEST-LOCK-RECONCILIATION-FIX1-C19`

State: **REJECTED BEFORE GATE REPLAY**

The first manifest update used a one-line patch context for
`"status": "production-accepted"`. That token appears in multiple accepted
screen entries, so the patch changed Screen01 v4 instead of Screen03 v2. The
immediate parsed-manifest audit correctly found zero active Screen01 versions
and two active Screen03 versions. No qualification gate or build followed this
invalid intermediate state.

The correction is blocked until REG-384 is registered and regression memory
passes. Manifest status edits must include screen id, version and adjacent
lineage fields in the patch context, then assert exactly one active version for
every affected screen immediately after mutation.
