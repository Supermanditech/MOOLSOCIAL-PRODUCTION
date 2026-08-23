# C30U large launcher patch output ambiguity

## Incident

The founder-only C30U launcher was submitted as one large add-file patch. The
tool output exceeded the evidence channel and was truncated, so the result
could not be treated as a verified release control.

## Root cause

The file was not split into bounded patch sections and was not immediately
followed by exact path, size, checksum and PowerShell parser checks.

## Permanent prevention

Large release-control additions use small verified patches. If any patch output
is truncated, read-only file existence, size, SHA-256 and parser checks are
mandatory before the file is used or the mutation is retried.

No AAB, deployment, upload or device mutation occurred.
