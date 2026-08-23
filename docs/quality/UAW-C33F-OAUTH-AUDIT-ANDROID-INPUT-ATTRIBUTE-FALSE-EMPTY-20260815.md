# UAW-C33F OAuth audit Android input attribute false empty

- Recorded at: `2026-08-15T10:59:47.0513319Z`
- Regression: `REG-20260815-2407-C33F-OAUTH-AUDIT-ANDROID-INPUT-ATTRIBUTE-FALSE-EMPTY`

The Android OAuth detail page displayed the expected Package name and SHA-1 labels, but serialized `value` attributes were absent. The first read therefore produced false/empty results that are not provider evidence.

The retry reads only those two labeled controls' live properties into transient memory and emits booleans. The OAuth client-ID control is never located or read.
