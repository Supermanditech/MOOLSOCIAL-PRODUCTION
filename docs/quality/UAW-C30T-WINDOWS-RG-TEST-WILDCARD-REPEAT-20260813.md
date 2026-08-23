# C30T Windows rg test-wildcard repeat

Date: 2026-08-13

A YouTube attribution audit repeated the known Windows mistake of passing wildcard path operands directly to `rg`. Two test scopes were rejected, so the partial result is not accepted as complete evidence.

The corrected audit must resolve exact files with `rg --files`, filter the returned paths, and search those literal owners. No runtime conclusion is drawn from the rejected command.
