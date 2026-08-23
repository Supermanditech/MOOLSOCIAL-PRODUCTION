# REG2642 — C33V pre-seal hidden-input authority was exposed

Date: 2026-08-16 IST

The first C33V source-phase gate rejected the unsealed state because
`authority.founderHiddenInputEntryAuthorized` was `true` while the two required
source qualification cycles were still incomplete.

The C33U-to-C33V state clone reset build, upload, install and founder build
approval authorities but retained this later qualified-state field. No source
manifest was sealed, no founder prompt opened, and no AAB, Play or OPPO action
occurred. Count no source-gate pass.

Keep hidden-input authority false throughout source qualification. Expose it
only after two cycles, final dual-host source replay and the separate qualified
state transition.
