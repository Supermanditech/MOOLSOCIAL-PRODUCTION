# REG2801 — C34L attestation hashtable-array invocation

Date: 17 August 2026
State: registered first PS7 fixture failure; zero real or external action

## Mistake

The first PS7 source-attestation checker invoked the writer with
`@(Get-C34LAttestationArguments ...)`, passing a hashtable as one positional
array element instead of splatting named arguments. Parameter binding rejected
`EvidenceType` before attestation behavior. The same call shape existed in the
Play and journey positive paths. Fixture cleanup ran and no real or external
action occurred.

## Prevention

Assign each generated parameter hashtable to a named local variable and invoke
the target with explicit hashtable splatting. Add a bounded static assertion
that no array-subexpression invocation remains before the one fresh host run.
