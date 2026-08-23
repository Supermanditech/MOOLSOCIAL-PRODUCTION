# C09 optional qualified-runner search failure

Date: 2026-08-07
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION`

## What failed

An optional ripgrep lookup for the prior qualified-mobile batch summary strings
found no matches in the bounded `scripts` and `docs\quality` roots. Bare
ripgrep therefore exited 1 and the orchestration surfaced a failed diagnostic.
No repository or device state changed.

## Root cause and prevention

The optional-search wrapper mandated by REG-132, REG-138 and REG-140 was not
used. All remaining optional searches in C09 explicitly distinguish exit 0
(matches), exit 1 (named zero-result) and exit greater than 1 (real error).
