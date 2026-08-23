# REG2844 — C34L transition FIX2 rg zero-match unguarded

Date: 17 August 2026
State: registered pre-behavior validation-command false failure

## Mistake

A combined transition validation command parsed successfully, then ran `rg` for
obsolete `New-C34LTransitionEvidence` references. Zero matches was the intended
result, but the unguarded `rg` exit code made the combined command fail. No
behavioral suite ran and no file changed after the result.

## Prevention

Run the authoritative parser and obsolete-reference inventory as separate shell
commands. For an expected-zero search, explicitly interpret exit 1 as success
only after asserting empty output; never compose it with the parser gate.
