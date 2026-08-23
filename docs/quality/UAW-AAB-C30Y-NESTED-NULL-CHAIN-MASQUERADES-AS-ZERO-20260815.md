# UAW AAB C30Y nested null chain masquerades as zero

Date: 2026-08-15
Regression: `REG-20260815-2196-AAB-C30Y-NESTED-NULL-CHAIN-MASQUERADES-AS-ZERO`
Status: registered before retry

## Finding

After bounded inventory resolved the exact C30X state and aggregate owners, the
first selected projection enumerated only their root property names. It then
read unverified nested paths including `releaseActions.build.count`. Those
paths are not root-owned in the current schema, and PowerShell's null-chain
`Count` behavior rendered misleading `0` values instead of proving the scalar
owners.

The projection is invalid release evidence. No AAB, upload, activation,
install, device, provider or credential action occurred.

## Prevention

- Enumerate each intermediate nested object's property names and runtime type
  before reading a scalar.
- Require every owner and final scalar to be non-null and type-correct.
- Validate build, upload and install counts as separately labeled properties.
- Never accept chained access through an unverified or null owner; a rendered
  zero is not proof that a numeric zero property exists.

## Resolution

The current nested schemas and runtime types were enumerated before a corrected
projection validated every named scalar separately. Both exact owners prove
r60.48 build/upload/install counts `0/0/0`, all current release/device
authorities false, and the historical failed r60.47 counts `1/1/1`.
