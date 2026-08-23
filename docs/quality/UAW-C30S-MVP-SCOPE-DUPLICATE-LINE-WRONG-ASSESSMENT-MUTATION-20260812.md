# C30S MVP scope duplicate-line wrong-assessment mutation

Date: 2026-08-12

A context-free single-line patch for `implementationDisposition` matched the
first of four identical properties and changed the historical C30K assessment
instead of the active C30S assessment. The immediate line-number read detected
the wrong target before parsing, gating, build or external action.

The historical line must be restored with a unique C30K manifest-hash anchor.
The C30S line must be updated with its unique C30S manifest-hash anchor. Every
remaining duplicated property requires an object-specific adjacent anchor and
an immediate exact-line verification.
