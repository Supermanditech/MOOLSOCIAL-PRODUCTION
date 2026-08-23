# REG2636 — C33U wrapper contract exclusion patch duplicated an operand

Date: 2026-08-16 IST

The first pre-seal C33U mapping patch added the new wrapper contract but
inserted its exclusion after the prefix of the prior first comparison. Static
readback showed a duplicated `[string]$state.contractId -cne` operand in the
condition. The wrapper was not executed, no source seal existed, and no build
or external authority was available.

The correction must replace the complete malformed condition lines, then parse
the wrapper in both PowerShell hosts and let the C33U candidate gate prove its
exact mapping and order before source qualification.
