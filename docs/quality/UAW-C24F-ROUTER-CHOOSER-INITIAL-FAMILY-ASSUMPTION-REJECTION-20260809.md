# C24F router chooser initial-family assumption rejection — 2026-08-09

The first router helper assumed Buy was selected whenever the requested route
belonged to Buy. From a visible Social source the chooser correctly opened on
Social, so the requested Buy action did not yet exist. The helper must select
the requested family explicitly before tapping its action; repeating the
already-selected family is safe and keeps the helper context-independent.
