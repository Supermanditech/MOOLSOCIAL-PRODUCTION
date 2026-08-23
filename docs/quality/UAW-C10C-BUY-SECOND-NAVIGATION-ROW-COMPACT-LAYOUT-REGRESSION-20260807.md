# C10C Buy compact-layout regression

## Observation

The first C10C host implementation correctly separated Buy-local destinations from the shared global Mool dock, but placed the five local tabs in a new 50-pixel row above the Buy content. Replacing the prior compact Buy dock with the shared global dock at the same time reduced the available content height enough to produce 13 failures in `buy_v2_screen_test.dart`, including overflow, chrome-ratio, geometry, off-screen target and downstream hit-test failures.

## Root cause

Navigation ownership was corrected without preserving the established compact-screen vertical budget. The implementation introduced a second persistent navigation row instead of reusing an existing header-height owner.

## Permanent prevention

Buy-local destination controls must fit inside existing header height. The complete Buy screen test, the C10C journey test and Flutter analysis are mandatory before qualification. No APK or OPPO mutation is allowed while this regression remains open.

## First repair result

Moving local destinations into the accepted header reduced the full Buy suite from 13 failures to 7. The remaining compact failures showed that the shared global dock itself still exceeded the prior Buy vertical budget; C10C remains blocked until those failures are eliminated without weakening fitment expectations.
