# REG2651 — C33Y post-seal pre-cycle state contradiction

Date: 2026-08-16 IST

C33Y successfully sealed and separately verified both source-manifest bindings.
Before cycle 1, exact readback showed that the sealed source gate's
`cycles=0` branch still required a null manifest hash and zero file count,
while the cycle runner requires the sealed hash and count to be populated.

The gate therefore conflated pre-seal composition with post-seal preparation.
Do not run a guaranteed-failing cycle. Reject C33Y before cycle 1 and build at
`0/0/0/0`.

The exact successor must define distinct pre-seal composition and post-seal
manifest-bound pre-cycle states before sealing. Null/zero bindings are valid
only in composition; populated exact bindings are required before cycle 1.
