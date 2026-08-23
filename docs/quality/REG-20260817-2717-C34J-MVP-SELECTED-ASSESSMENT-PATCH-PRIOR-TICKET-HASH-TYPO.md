# REG2717 — C34J selected-assessment prior-ticket hash typo

Date: 2026-08-17 IST

A bounded MVP selected-assessment patch included an incorrectly retyped prior
C34I ticket SHA-256 in its context. `apply_patch` rejected the hunk with zero
writes. The candidate ticket and every external action remained unchanged.

The corrected operation projects the exact current assessment from parsed live
JSON, uses the literal hash without transformation, patches identity separately
and then validates the complete JSON plus MVP scope gate.
