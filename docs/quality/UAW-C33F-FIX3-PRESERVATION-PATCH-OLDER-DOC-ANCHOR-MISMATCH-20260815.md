# UAW-C33F FIX3 preservation patch older-document anchor mismatch

- Recorded at: `2026-08-15T10:43:33.8912933Z`
- Regression: `REG-20260815-2395-C33F-FIX3-PRESERVATION-PATCH-OLDER-DOC-ANCHOR-MISMATCH`

The first combined patch for the missing transient Firebase debug evidence used an inferred sentence for an older quality document. `apply_patch` rejected the complete patch atomically, so no registry, ticket, or documentation change from that attempt was applied.

The retry must use the exact current anchors already read from every target and must split the durable pointer migration from the historical-document amendment.
