# REG2818 — C34L retained privacy artifact-path phone false positive

Date: 17 August 2026
State: registered first PS7 retained-fixture rejection; zero real/external action

## Mistake

The first fresh PS7 retained-evidence fixture rejected the approved AAB
`artifactPath` as a phone-shaped private value because canonical path/version
digits matched the generic phone scan. The scanner exempted leaf `path` but not
the exact approved path-property names. Only a unique retained-fixture root was
touched and no real or external action occurred.

## Prevention

Make phone detection field-aware after exact schema validation. Exempt only
approved canonical path/hash/version/count fields in their exact positions;
retain phone-shaped rejection for unknown/private/contact fields and add both
canonical artifact-path allow and private-phone exact-class negatives.
