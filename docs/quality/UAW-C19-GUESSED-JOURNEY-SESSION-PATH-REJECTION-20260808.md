# C19 guessed JourneySession path rejection

Date: 8 August 2026

Ticket: `UAW-PERSONAL-MVP-SCREEN03-PROFILE-PROVENANCE-TEST-LOCK-RECONCILIATION-FIX1-C19`

State: **REJECTED; CORRECTED INVENTORY RULE ACTIVE**

The first profile-marker owner inspection correctly printed the platform test
diff but then queried a guessed path,
`apps/mobile/lib/ui_v2/journey/journey_session.dart`. The diff itself named the
real owner as `lib/features/journey01/journey_session.dart`, so the mixed command
exited nonzero and is not accepted as owner evidence.

Before retrying, this mistake was registered as REG-383 and the permanent
regression-memory gate was required. Future owner inspection derives literal
paths from the test/source reference or `rg --files`; conventional directory
guesses are not combined with otherwise valid evidence commands.
