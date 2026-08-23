# C21H source-fingerprint recomputation sort-order rejection — 2026-08-08

The first C21H aggregate probe computed category hashes correctly but concatenated and sorted the final `hash  path` records, which sorts primarily by hash. C21G instead globally sorts FileInfo objects by full path before constructing records. The probe returned `AE9F...`, not sealed fingerprint `3E77391C...`, and is rejected.

REG-20260808-498 requires the exact C21G algorithm and a strict match before build authorization. No build or device mutation occurred.
