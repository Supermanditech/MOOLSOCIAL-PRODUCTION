# AAB second multi-document resolution context mismatch

Date: 14 August 2026
Scope: source-only C30X hard-gate documentation

A second combined resolution patch manually reflowed an existing Markdown
sentence and did not match the file. `apply_patch` rejected the whole patch,
so no partial status change was accepted.

The correction updates machine statuses separately, then appends to each
document using its exact final line. No AAB, Play/OPPO action, deployment or
secret access occurred.
