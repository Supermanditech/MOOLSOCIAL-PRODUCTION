# REG2824 — C34L retained privacy branch phone false positive

Date: 17 August 2026
State: registered fresh PS7 retained-fixture rejection; zero external action

## Mistake

After aligning the fixture to the authoritative C30T build-provenance schema,
the fresh PS7 retained run rejected canonical public branch
`remediation/prototype-conformance-2026-07-20` as phone-shaped. Only a synthetic
retained-fixture root was touched and no retry, later mutation, or external
action followed.

## Prevention

After exact schema validation, exempt only the canonical public `branch` field
in the build-provenance object from phone-shape scanning while still validating
its exact authorized value. Retain phone rejection for unknown/private/contact
fields and add canonical-branch allow coverage.
