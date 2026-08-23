# UAW C30T Email OTP contract owner path guess rejection — 13 August 2026

The first Email OTP diagnostic included the guessed path `apps/mobile/lib/features/journey01/review_journey_contracts.dart`. That file does not exist. The compound read still found the real Email OTP gateway, session and Screen 03 owners, but the missing-path output makes the diagnostic inadmissible as a complete owner read.

Before continuing, the mistake was registered. Authentication contract discovery must begin with an exact symbol search inside a verified existing root and then read only returned paths. Convention-derived filenames may not be appended to grouped reads, and a later successful command may not mask a missing-path failure.
