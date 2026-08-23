# C34F combined aggregate reset patch context mismatch

Date: 2026-08-17 IST

Status: registered pre-seal; retry requires exact small aggregate hunks

The first C34F aggregate reset patch combined identity, historical-candidate,
source-qualification, authority, count, privacy and rejection changes. The
patch engine rejected the operation atomically when a source-qualification
context did not match the exact cloned aggregate bytes. The aggregate file was
not changed by the failed patch.

The root cause was attempting a large remembered state-to-aggregate rewrite
instead of reading and changing each exact aggregate section independently.

Before retry, parse the untouched aggregate, read the exact current section,
apply one bounded hunk, parse again, and repeat. Count no C34F qualification,
source seal, test, build, Play or device result from the failed patch.
