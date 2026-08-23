# C30T PowerShell question-wildcard status truncation — 2026-08-13

## Outcome

A follow-up read-only dirty-owner summary used a PowerShell question-mark
wildcard with the like operator. The predicate matched tracked rows as well as
untracked rows and emitted a large truncated listing. The listing is rejected
and is not used as C30T evidence.

The command changed no file, source, build artifact, device or external
service. No retry of that listing is permitted.

## Root cause and prevention

The status prefix was treated as a literal while using a wildcard operator.
Future status classification either avoids full untracked enumeration entirely
or uses an anchored literal-safe expression after a bounded owner inventory.
Only bounded scalar results may be emitted. Truncated status output can never
support release authority.

Because the regression registry and this evidence are source-sealed, both
no-AAB qualification cycles must be repeated before build authority can be
activated.
