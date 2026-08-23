# C20C guessed separate Mool brand owner path rejection

Date: 2026-08-08
Ticket phase: C20C preselection

A bounded symbol search located `MoolBrand`, `identityNavy` and
`identityWhite` in the existing shared owner
`apps/mobile/lib/core/design/mool_design_system.dart`. The same compound
command then guessed and attempted to read
`apps/mobile/lib/core/design/mool_brand.dart`, which does not exist.
`Get-Content` rejected the guessed path.

No C20C ticket, scope, source, test, APK, install or OPPO mutation followed.
C20C must reuse the exact discovered `MoolBrand` owner in
`mool_design_system.dart`; it may not invent a separate brand file.
