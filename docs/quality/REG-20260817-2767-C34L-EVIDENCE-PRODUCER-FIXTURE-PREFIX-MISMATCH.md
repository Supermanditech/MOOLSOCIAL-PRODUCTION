# REG2767 — C34L evidence-producer fixture prefix mismatch

Date: 17 August 2026
State: registered first fixture failure; retained fixture preserved

## Mistake

The first PowerShell 7 evidence-producer fixture used
`tmp/c34l-evidence-producer-fixtures-*`. Four fixture-only evidence records were
created, but the authoritative retained-evidence checker correctly accepts only
an exact `tmp/c34l-retained-evidence-fixtures-*/state.json` root and rejected
the round trip before negative cases. The agent stopped without retry or patch.
The 15-file fixture root is preserved as failure evidence. No production state,
Play, OPPO, browser, device, private, secret or external action occurred.

## Root cause and prevention

The new producer checker invented a parallel fixture namespace instead of
reusing the authoritative retained-checker confinement contract. All producer
fixture paths must be projected from that exact accepted prefix, with state and
aggregate inside the same root. Re-run only with a fresh unique root after the
registry gate; never weaken the retained checker or reuse/delete the failed
fixture.
