# REG2807 — C34L attestation type-negative expected class masked

Date: 17 August 2026
State: registered third PS7 exact-class fixture failure; zero external action

## Mistake

The third PS7 attestation run reached the injected evidence-type negative and
did reject, but the fixture helper derived the writer's `EvidenceType` argument
from the already-mutated capture. That changed the expected leaf/specification
before the intended capture-type identity check, so the asserted failure class
was masked. Cleanup ran and no real or external action occurred.

## Prevention

Keep the invocation contract fixed to
`play_internal_testing_activation` while mutating only the retained capture
field. Every negative must assert its exact intended rejection class rather than
accepting any earlier failure.
