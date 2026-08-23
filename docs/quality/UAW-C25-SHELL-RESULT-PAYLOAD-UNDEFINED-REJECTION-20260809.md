# C25 shell-result payload extraction — rejection

Date: 2026-08-09

## Rejected audit

The exact config paths were valid and the shell calls completed, but the execution composer attempted to read a nonexistent `output` property. Only `undefined` markers reached the audit transcript. None of the target files is considered read from that call.

## Permanent correction

Forward the complete shell-call result directly or perform one bounded stdout read without manually extracting an assumed property. Require the complete visible file content before using any governing record for C25 selection or implementation.
