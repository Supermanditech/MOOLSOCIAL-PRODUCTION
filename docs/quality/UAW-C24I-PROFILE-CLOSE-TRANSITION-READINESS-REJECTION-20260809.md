# C24I profile-close transition readiness rejection

Date: 2026-08-09

The journey tapped the currently verified profile-sheet `Close` action, waited a fixed 800 ms and refreshed the Android hierarchy. The expected Social `Open MoolSocial actions` clickable node was not present, so the command stopped before opening the chooser or tapping Buy.

No unverified coordinate was used. The retry must poll bounded fresh hierarchies for a stable, uniquely owned clickable control rather than treating a fixed delay as readiness.
