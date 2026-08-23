# REG2805 — C34L OPPO privacy canonical action-name false positive

Date: 17 August 2026
State: registered second PS7 fixture rejection; zero real or external action

## Mistake

After the JWT correction, the fresh PS7 OPPO transaction fixture rejected the
required action-count field `passwordlessEmailSend` because a generic
forbidden-name substring scan treated the authoritative word `email` as a
private field. Unique fixtures were cleaned and no real or external action
occurred.

## Prevention

Apply exact allowlist validation before private-name rejection and exempt only
the exact canonical `passwordlessEmailSend` action-count member in its approved
schema position. Preserve rejection of unknown/private property names and
values everywhere else.
