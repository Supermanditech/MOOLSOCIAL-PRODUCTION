# UAW C18 unbounded shared-brand hash-search truncation rejection — 2026-08-08

## Rejected attempt

A repository-wide ripgrep search for the current
`moolsocial_brand_motion.dart` SHA-256 returned more output than the tool
budget and was truncated. The visible fragments are not admitted as evidence
for when, why or under which ticket the shared owner changed.

No production source, test, accepted reference, runtime, build, install or
device state was mutated by the rejected read-only search.

## Root cause

The search included all historical artifact manifests even though the
question required only the earliest bounded successor evidence after R50.

## Permanent prevention

Hash-provenance searches must first limit candidate evidence roots by date or
ticket sequence and return only filenames or a bounded first/last match set.
Large artifact trees are never searched with unrestricted matching output.
Truncated results are discarded and the permanent memory gate must pass before
the narrower retry.
