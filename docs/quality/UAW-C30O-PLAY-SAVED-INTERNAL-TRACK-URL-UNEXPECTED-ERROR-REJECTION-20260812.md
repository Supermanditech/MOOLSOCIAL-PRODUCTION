# C30O saved Internal-track URL unexpected-error rejection

- Date: 2026-08-12
- Scope: read-only Google Play Console navigation to the authorized private Internal testing track
- Result: rejected with Play Console error `72E46BF7`

## Mistake

The previously observed app-scoped Internal-testing track URL was reused after the Play Console window had returned to the dashboard. Play Console displayed `An unexpected error has occurred. Please try again. (72E46BF7)` instead of the track page.

## Root cause

The saved opaque track route was treated as durable across the changed Play Console session without first re-resolving the current internal-track route from the live dashboard.

## Permanent prevention

Do not retry the saved opaque track URL or infer validity from the prior session. Return to the app dashboard, use the exact `Release your app early for internal testing without review` task exposed by the live Console, and verify the resulting track/tester page before any tester or release write.

## Safety outcome

No form, tester list, track, release, artifact, tester access, or other Play data changed.
