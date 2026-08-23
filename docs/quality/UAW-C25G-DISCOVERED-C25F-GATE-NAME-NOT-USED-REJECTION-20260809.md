# C25G discovered C25F gate name not used

Date: 2026-08-09

## Rejection

The bounded file inventory printed the exact C25F gate owner, but the same
diagnostic retained the previously guessed filename in its inspection list and
failed.

## Recovery

No mutation occurred. The next read uses only the exact discovered path in a
separate bounded command.

## Permanent rule

Discovery precedes inspection. A disproven guessed path must not survive into
the inspection command.
