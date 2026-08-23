# UAW C30U source-manifest compare byte-array AsSpan rejection

Date: 2026-08-14

## Incident

The protected source-union OutputPath preflight passed with 1,143 source owners,
all 206 protected owners and zero missing. Its immediate ComparePath self-test
then failed before comparison because PowerShell tried to invoke `.AsSpan()` on
`System.Byte` values.

## Root cause and prevention

`AsSpan` is not a byte-array instance method available through this
PowerShell/.NET binding surface. Compare the retained file and freshly composed
payload with exact byte length plus SHA-256 equality instead. Test OutputPath
and ComparePath modes separately before final cycle 1 or cycle 2.

The compare owner now calculates the existing byte length and SHA-256, compares
both to the freshly composed payload and passes PowerShell parser validation.
The next no-mutation pre-cycle self-test exercises OutputPath followed
immediately by ComparePath on a new immutable diagnostic owner.

That exact self-test passes in both modes at 1,144 source owners, all 206
protected owners, zero missing owners and fingerprint
`90FF7C1D969B31A530D01AD9A093783A73C9CB3ED84E302735DC9AA26DABD37E`.

No accepted-v2 manifest or cycle seal was created. No AAB, Play or OPPO mutation
occurred.
