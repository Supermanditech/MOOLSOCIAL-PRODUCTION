# C25G malformed regression patch add-file boundary

Date: 2026-08-09

## Rejection

The first REG839 registration patch contained an invalid update-hunk boundary
before an Add File section. The patch parser rejected the entire mutation.

## Recovery

The rejected patch applied nothing. One syntactically complete bounded patch
registered REG839 and this recurrence together.

## Permanent rule

Complete every update hunk with valid context before starting Add File content,
and verify all-or-none rejection before retrying.
