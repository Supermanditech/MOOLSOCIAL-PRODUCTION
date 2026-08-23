# C30O YouTube privacy URL broad documentation search rejection

Date: `2026-08-12`

State: `REJECTED_READ_ONLY_SEARCH_NO_REPOSITORY_OR_EXTERNAL_MUTATION`

The first C30O search for privacy, deletion and revocation links combined the
known live web owners with the full `docs` tree. It returned 309 matches across
unrelated historical and product records. Although the command completed, the
mixed result is rejected as compliance evidence because it did not preserve an
exact current public-owner boundary.

No repository, device, browser or provider state changed.

Permanent prevention: resolve and read only the exact current public owners
`apps/web/public/privacy/index.html`, `disconnect/index.html`,
`delete-account/index.html` and `youtube-api/index.html`, one owner per bounded
read. Current URLs and copy must come from those literal owners or separately
verified live pages; the broad documentation result cannot support a product
or reviewer-package decision.
