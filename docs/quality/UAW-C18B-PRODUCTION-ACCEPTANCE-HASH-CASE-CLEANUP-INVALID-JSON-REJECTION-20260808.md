# UAW C18B production-acceptance hash-case cleanup invalid-JSON rejection — 2026-08-08

## Rejected edit

While the new, not-yet-qualified Screen01 v4 package was being authored, a
cosmetic cleanup of one SHA-256 string appended `.toLowerCase()` outside the
JSON string. That made the new `production-acceptance.json` syntactically
invalid before any validation or gate could accept it.

No existing v1–v3 reference, production source, build, install or device state
was changed by this rejected edit.

## Prevention

Machine-readable hashes remain literal 64-character hexadecimal strings.
Cosmetic case normalization is never expressed as code inside JSON. The exact
line must be corrected with a literal lowercase hash, followed by an
independent JSON parse before checksum or manifest generation.
