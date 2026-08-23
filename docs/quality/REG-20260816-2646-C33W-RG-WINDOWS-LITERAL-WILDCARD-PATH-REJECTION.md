# REG2646 — C33W rg used a Windows literal wildcard path

Date: 2026-08-16 IST

The first C33W stale-identity audit passed
`docs/quality/UAW-C33W-*.md` as a positional `rg` path. On Windows the wildcard
was treated as an invalid literal path, so the document portion of the audit
did not run.

No repository or external state changed. Count no document-audit result. Use
`rg --files` with a filename filter or pass the three exact C33W document paths
explicitly, then complete identity and historical-label readback before any
source seal.
