# C32M fingerprint evidence broad artifact-search timeout recurrence

Date: 15 August 2026
Regression: `REG-20260815-2258-C32M-FINGERPRINT-EVIDENCE-BROAD-ARTIFACT-SEARCH-TIMEOUT-RECURRENCE`

## Failure

A literal lookup for the prior 18-file fingerprint included the retained `artifacts` tree and timed out. The command changed no file and produced no accepted evidence.

## Prevention

The retry is restricted to the exact C32J chained-scope failure evidence and active C32M machine-state files already named by the registry. Large retained evidence trees are excluded from discovery searches.
