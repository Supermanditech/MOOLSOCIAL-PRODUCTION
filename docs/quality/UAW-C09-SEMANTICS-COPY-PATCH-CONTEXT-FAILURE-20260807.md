# C09 semantics-copy patch context failure

Date: 2026-08-07

A one-line semantics-copy patch included a nonexistent
`explicitChildNodes: true` context line. `apply_patch` rejected the operation
before changing the design-system file. The exact bounded source lines were
then read and the replacement was reapplied using verbatim context.

Small patches still require current copied context; nearby context from another
Semantics widget is never inferred.
