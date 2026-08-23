# C30T Create authentication and composer dock test contracts

Date: 2026-08-13
Scope: exact C29O and C27D focused Social tests

## Observed failure

The bounded three-test rerun proved the Feed ownership assertion and the real 140% Videos overflow correction, then exposed two stale test assumptions:

1. C29O tapped Create with an unstarted unauthenticated `JourneySession` but expected the authenticated composer.
2. C27D entered the full-screen Create composer and immediately expected the Social destination dock to remain rendered.

Production behavior is intentionally different: Create requires Firebase authentication, and the composer hides the dock until the real Close action returns to Feed.

No AAB build, upload, Play update, device mutation, backend write, Create write or Chat message occurred. C30T counters remain zero.

## Bounded correction

- Start C29O with an explicit signed-in review gateway before exercising its authenticated Create accessibility path.
- In C27D, verify Videos and Feed through the dock, enter Create, assert the workbench and hidden dock, close through `screen04-create-close`, prove the Feed dock state, then continue to Shorts.

## Resolution

C29O now starts an explicitly authenticated session. C27D now follows the real full-screen composer lifecycle and proves the Feed return before continuing. Analyzer passed with no issues, and the exact three-test partition passed all six test cases.
