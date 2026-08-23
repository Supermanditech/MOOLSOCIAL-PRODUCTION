# C24B invented MoolRadii token compile rejection — 2026-08-09

The first C24B focused batch rejected because the new shared primitive referenced nonexistent `MoolRadii.md` and `MoolRadii.lg` members. The existing radius owner exposes `control`, `card`, `sheet`, `floating` and `capsule`.

No runtime candidate or APK was produced. The concurrent C23 Home semantics suites passed, but C24B remains incomplete until the primitive compiles and the entire focused batch passes together.

The correction uses `MoolRadii.control` for compact icon surfaces and `MoolRadii.card` for search and primary controls. This mistake is permanently registered as `REG-20260809-611-C24B-INVENTED-MOOL-RADII-MD-LG-TOKENS`.
