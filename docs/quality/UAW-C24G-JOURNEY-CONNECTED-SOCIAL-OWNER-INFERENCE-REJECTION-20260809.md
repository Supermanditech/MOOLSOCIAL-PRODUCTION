# C24G Journey connected Social owner inference rejection

Date: 2026-08-09
Regression: `REG-20260809-742-C24G-JOURNEY-CONNECTED-SOCIAL-DESTINATION-OWNER-INFERRED`

The connected Social Shorts action from the legacy Ride root did not expose
`mvp-action-root-social`. The assumed generic route owner is rejected. The
correction must inspect the action's literal route and the first matching
router branch, then bind the test to that branch's proven current owner.

## Resolution

`personalMvpActionChoiceRoots` intentionally excludes protected Social and
Buy. Under the explicit legacy test flag, Social routes to `section-social`.
The corrected journey verifies Shorts there, reaches Buy through search
without an intermediate Home, and the complete Journey01 file passed 12/12.
