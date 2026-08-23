# C24C Fix1 removed Home cards/global dock rejection — 2026-08-09

Eleven historical Fix1 route cases used removed `mool-action-*`,
`mool-root-selected`, and `mool-root-chat` controls and expected destination
Back to restore Home. Those contracts predated the compact Home chooser and
the one connected MoolSocial launcher.

REG660 preserves the locked 6+17 wording projection while migrating routing to
current `mool-home-*` actions, unchanged-owner connected-chooser dismissal,
and Home header Chat continuity.
