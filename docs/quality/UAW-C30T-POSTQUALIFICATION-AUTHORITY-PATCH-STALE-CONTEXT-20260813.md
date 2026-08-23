# C30T postqualification authority patch stale context — 2026-08-13

## Outcome

The first atomic postqualification authorization patch failed verification and
made zero mutation. It expected the AAB owner to remain on the pre-cycle audit
hold, while successful cycle 2 had correctly transitioned the owner to the
pre-AAB-passed state.

## Root cause and prevention

The patch context came from the pre-cycle reset rather than the qualifier's
declared cycle-2 transition. Future postqualification patches anchor both
machine owners to pre_aab_audit_passed_founder_aab_authorization_required;
only invalidation patches use the continuous-audit hold context.

Because this registry evidence is source-sealed, a fresh two-cycle no-AAB pair
is required before build authority can be activated.
