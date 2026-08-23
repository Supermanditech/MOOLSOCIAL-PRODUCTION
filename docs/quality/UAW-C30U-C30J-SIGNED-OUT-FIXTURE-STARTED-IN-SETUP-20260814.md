# C30U C30J signed-out fixture started in setup

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Failure

After migrating the C30J journey to call `JourneySession.start()`, its exact
named test failed before the YouTube explanation tap:

- Expected stage: `ready`
- Actual stage: `setup`
- Startup truth: `snapshot=false`, `setupComplete=false`, setup version `0/5`

## Root cause

The C30J `_Owners` fixture constructs an empty default `JourneySession`. The
test is intended to model a signed-out viewer who has completed onboarding, but
its store contains no completed setup snapshot. Starting that session correctly
enters setup.

## Prevention

Reuse the exact current signed-out-ready in-memory journey-store pattern from a
passing Social test owner. Explicitly seed setup completion/version, start the
session, assert `ready` and `isAuthenticated == false`, then exercise the
explanation and continuation. Never bypass `start()` or treat booting/setup as
a signed-out-ready state.

## Release effect

The focused analyzer passed. The named journey failed before any backend or
device action. No C30U source manifest/cycle seal exists and
build/upload/install counts remain `0/0/0`.

## Repair verification

The C30J fixture now uses the same current `MemoryJourneyStore` and completed
`JourneySnapshot` pattern as the passing Social signed-out owner, with
`allowGuestReady: true`. Startup reports setup version `5/5`, stage `ready`,
and `authenticated=false`. The exact signed-out C30J journey then passes.
