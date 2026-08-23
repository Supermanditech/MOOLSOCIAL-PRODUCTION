# UAW C30T Create-draft auth-fixture static-analysis rejection — 2026-08-13

## Outcome

The authenticated draft-test fixture failed static analysis:

1. `JourneySnapshot` was given the guessed, nonexistent named parameter
   `completedSetupExperienceVersion`.
2. The nullable `_Owners` constructor argument named `journey` shadowed the
   initialized non-null field, so `journey.emailAddress` was an unsafe nullable
   access.

No Flutter test ran. No product or external state changed.

## Permanent prevention

Use the proven minimal JourneySnapshot constructor already present in C30T
tests, and address the initialized non-null field explicitly as
`this.journey` when a nullable constructor argument shares its name. Run
targeted static analysis before retrying the widget test.
