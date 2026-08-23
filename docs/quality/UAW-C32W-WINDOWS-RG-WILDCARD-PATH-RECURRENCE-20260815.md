# C32W Windows ripgrep wildcard path recurrence

Regression: `REG-20260815-2286-C32W-WINDOWS-RG-WILDCARD-PATH-RECURRENCE`

One evidence search included `apps/mobile/test/uaw_personal_mvp_*` as a literal
path. Windows rejected it, leaving a partial ripgrep result and exit code 1.
The wildcard will not be retried; only exact inventoried test paths are used for
the C32X applicability comparison.
