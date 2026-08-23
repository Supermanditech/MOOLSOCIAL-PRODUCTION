# C31E optional type search no-match combined shell failure — 15 August 2026

The C31E backend inventory combined required Chat source reads with an optional
ripgrep lookup for `getSignedUrl` declarations under an installed dependency
path. The required source reads completed, but the optional lookup found no
match and returned ripgrep exit 1. Under the command's stop-on-error policy,
that normal no-match result caused the combined shell invocation to be marked
failed.

No source, dependency, generated output, device, backend or external state was
changed. The retry must isolate the optional search, capture its native exit
code and accept only 0 (matches) or 1 (no matches). Required reads may not be
coupled to that optional exit status.

The corrected isolated lookup completed with explicit
`optional_type_search=no_matches`, native exit 1 accepted, and the regression
memory gate passed. The incident is resolved and its prevention remains active.
