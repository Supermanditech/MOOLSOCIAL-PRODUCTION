# C24B2 private catalogue partial-deletion rejection — 2026-08-09

The first removal patch deleted the private catalogue types but left their value list under a `List<Never>` placeholder. The retained list still referenced the deleted constructors, so the intermediate source was not compile-valid.

No test or completion claim was made. The correction removes the entire obsolete list and leaves the new shared catalogue as the sole owner. This mistake is permanently registered as `REG-20260809-620-C24B2-PRIVATE-CATALOGUE-PARTIAL-DELETION-LEFT-INVALID-RETIREMENT-LIST`.
