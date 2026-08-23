# REG2718 — C34J prior-C34I assessment hash segment transposed

Date: 2026-08-17 IST

Readback found that the newly inserted historical C34I assessment transposed a
segment of the ticket SHA-256. This was detected before the MVP gate, source
seal, tests, build authority or any external action.

The field is corrected only from the retained `Get-FileHash` result. Both the
selected C34J and prior C34I assessment paths and hashes must match their exact
on-disk files before the MVP scope gate can pass.
