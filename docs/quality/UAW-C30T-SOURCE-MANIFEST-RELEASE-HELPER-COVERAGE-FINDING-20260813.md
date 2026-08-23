# C30T source-manifest release-helper coverage finding

Date: 2026-08-13

The new metadata-aware release registrant verifier was mandatory in preflight and post-test recovery, but it was not yet listed in the source aggregate manifest that the future AAB wrapper requires to remain byte-identical after qualification.

The helper is now an explicit source-manifest owner. Static readiness requires exactly three qualifier references: preflight use, post-test use and manifest inclusion. No build or external state changes.
