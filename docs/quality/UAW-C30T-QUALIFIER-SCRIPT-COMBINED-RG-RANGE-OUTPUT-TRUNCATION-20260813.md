# C30T qualifier script combined-search truncation

Date: 2026-08-13
Regression: `REG-20260813-2003-C30T-QUALIFIER-SCRIPT-COMBINED-RG-RANGE-OUTPUT-TRUNCATION`

## Incident

During read-only source-fingerprint reconciliation, one diagnostic command
combined broad `rg` results from the large C30T qualification script with a
fixed 95-line source read. The result exceeded the evidence channel and was
truncated. The output is rejected and was not used for a release conclusion.

## Root cause

The command did not first resolve one exact definition line and then constrain
the source read around that line.

## Permanent prevention

Search one exact symbol at a time, cap matches, and read only a 20-30 line
region around the verified line. Broad qualifier matches and large fixed source
ranges must not be combined in one evidence call.

This incident grants no AAB, upload, install, deployment, or device authority.
