# C30X FIX2 PowerShell source-needle interpolation

Date: 2026-08-14
Incident: `REG-20260814-2163-AAB-C30X-FIX2-POWERSHELL-NEEDLE-INTERPOLATION`
State: registered before retry

The first new FIX2 order-contract run failed closed because the source needle
for `$state.buildAuthorization = 'consumed'` used an expandable PowerShell
string. PowerShell interpolated `$state`, so the literal source fragment could
not be found. The postbuild-block needle contained `$_` with the same defect.

The bounded correction is to use literal single-quoted source needles, with
embedded single quotes doubled, for every dollar-prefixed PowerShell fragment.
No build, authority consumption, upload, device action or secret access
occurred.

## Resolution

All dollar-prefixed source fragments in the FIX2 checker use literal
single-quoted needles. The checker passes on PowerShell 7 and Windows
PowerShell, and verifies the complete gate → config-only → manifest → preflight
result → authority consumption → appbundle ordering.
