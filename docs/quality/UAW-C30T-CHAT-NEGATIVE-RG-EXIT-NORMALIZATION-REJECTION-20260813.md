# C30T Chat negative-`rg` exit normalization rejection — 2026-08-13

The release-restoration command intentionally searched for removed Chat symbols. `rg` found none and returned its standard exit code 1, but the command did not normalize that expected negative result, so the shell reported failure after all preceding checks passed.

Prevention: capture `rg` output and explicitly accept exit 1 as the passing no-match result for negative assertions; reject only exit codes above 1.
