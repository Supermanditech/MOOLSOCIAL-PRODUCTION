# REG2793 — C34L registry ID-property guess and premature retry

Date: 17 August 2026
State: registered false diagnostic and premature follow-up; zero mutation

## Mistake

The primary agent projected registry entries with guessed property
`regressionId` instead of the authoritative `id`. The command exited zero but
reported a false REG2790 count of zero and blank tail IDs. The agent then
inspected the last entry to discover the schema before registering the false
diagnostic, which was a premature retry. Both commands were read-only.

## Prevention

Inspect the parsed registry schema before projecting entry identifiers, use
the exact `id` property, and treat an internally impossible successful result
as an unexpected failure that must be registered before any follow-up query.
