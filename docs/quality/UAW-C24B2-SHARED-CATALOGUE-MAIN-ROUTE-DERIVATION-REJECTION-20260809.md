# C24B2 shared-catalogue main-route derivation rejection — 2026-08-09

The first catalogue consolidation derived the compatibility `personalMoolRootActions` routes from each family's first direct subaction. That would have changed Social and Buy to query-bearing routes and retained inconsistent legacy family routes for Eat, Ride, Book and Work.

The correction freezes the accepted main default routes directly on each shared family and derives the compatibility projection from `family.route`. C24B2 main-family taps only select a family in place, so they do not reinterpret or consume those routes.

This mistake is permanently registered as `REG-20260809-618-C24B2-CATALOGUE-CONSOLIDATION-DERIVED-WRONG-MAIN-ROUTES`.
