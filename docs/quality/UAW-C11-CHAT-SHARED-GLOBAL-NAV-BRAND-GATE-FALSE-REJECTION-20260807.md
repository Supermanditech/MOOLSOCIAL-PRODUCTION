# C11 shared-global-navigation brand-gate false rejection

Date: 2026-08-07

Regression ID:
`REG-20260807-242-C11-CHAT-SHARED-GLOBAL-NAV-BRAND-GATE-FALSE-REJECTION`

The app brand gate first rejected Chat because it still searched
`chat_inbox_screen.dart` for a directly rendered Mool launcher icon. C10D
correctly moved Chat navigation into the shared `ChatPageScaffold`, which uses
`MoolGlobalNavigationV2`; that shared owner renders
`MoolBrand.moolLauncherIcon` for every destination.

After that chain was corrected, the same stale ownership assumption rejected
the Social consumer because it still expected a direct Mool item inside the
retired Screen 04 capability rail. C10B correctly moved the Social consumer to
the same global owner. The separate creator rail still retains and must retain
its canonical grid launcher until that protected journey receives its own
authorized migration.

The product implementation retained the canonical launcher, but the gate kept
an obsolete direct-screen ownership assumption and therefore emitted a false
failure.

Permanent prevention: the brand gate validates both sides of each shared-owner
chain—Chat and the Social consumer must use `MoolGlobalNavigationV2`, and that
component must render `MoolBrand.moolLauncherIcon`. Screen-specific duplicate
icons are not required and must not be reintroduced merely to satisfy stale
source text. Unmigrated protected owners remain checked directly.
