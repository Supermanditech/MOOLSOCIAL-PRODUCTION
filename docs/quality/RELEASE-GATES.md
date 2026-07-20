# Release gates

## Every pull request

1. Dart formatting, static analysis and unit/widget tests.
2. SQL Connect schema and generated-client validation.
3. Contract tests for touched operations.
4. No destructive production migration.
5. No generated secret or live Firebase configuration committed.
6. Accessibility semantics and minimum tap-target checks on touched UI.
7. Every touched user-facing screen has an approved-prototype comparison;
   current implementation goldens alone cannot approve visual or interaction
   conformance.

## Every staging promotion

1. Build from a tagged commit, never from an uncommitted laptop state.
2. Deploy schema/connectors before clients only when backward-compatible.
3. Use `COMPATIBLE` schema validation after production contains data.
4. Run the clean-state journey replay on the emulator and staging.
5. Produce Android and iOS artifacts from the same source commit.
6. Upload Android to App Distribution and iOS to TestFlight.
7. Run Flutter integration tests on the Android and iOS device matrix.
8. Verify Crashlytics, Performance and business-intent events by platform.
9. Founder-approved screenwise visual and tap-path evidence is attached for
   every journey changed by `UI-CONFORMANCE-001`.

## Every production promotion

1. Android and iOS staging/production artifacts share the same source commit.
2. Feature is disabled by default and enabled through a reviewed flag.
3. Backup and rollback route are verified.
4. Payment/stock/payout mutations pass duplicate and retry tests.
5. No P0/P1 issue and no blocked core intent path.
6. Founder completes the exact staging acceptance replay.
7. Begin with a percentage rollout; stop automatically on guardrail breach.

## Non-negotiable command behavior

- Every irreversible command has an idempotency key.
- The server owns price, stock, money, eligibility and state transitions.
- Provider callbacks are authenticated, deduplicated and replayable.
- A timeout is not treated as a failure when the authoritative result is
  unknown; the app reconciles before retrying.
- UI success is shown only after an authoritative success response.
