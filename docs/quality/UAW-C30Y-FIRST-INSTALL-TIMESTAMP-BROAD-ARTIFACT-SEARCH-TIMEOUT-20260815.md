# C30Y first-install timestamp broad artifact-search timeout

Date: 2026-08-15
Regression: `REG-20260815-2216-C30Y-FIRST-INSTALL-TIMESTAMP-BROAD-ARTIFACT-SEARCH-TIMEOUT`
Status: resolved; broad retry rejected and exact evidence recorded

## Finding

A literal first-install timestamp search targeted the complete
`artifacts/quality` archive and timed out with exit 124 before returning usable
evidence. The command changed no files or device state and its output is not
accepted.

## Prevention

OPPO install reconciliation reads the exact current package fields and the
selected C30Y state, and uses only already located predecessor evidence. The
full historical artifact archive is not searched again for a timestamp. No
build, Play, OPPO, provider, credential or external-service mutation occurred.
