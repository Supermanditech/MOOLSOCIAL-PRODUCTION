# C25F C16F guessed Care local rail owner key rejection

- Date: 2026-08-09
- Status: registered before retry

The first C16F migration changed the predecessor absence assertion to require `book-local-navigation` without first reading the current C25 owner key. The production Care rail uses `care-book-local-navigation`, so the guessed assertion failed while the reduced-motion test passed.

The correction binds the test to the exact current key and leaves runtime code unchanged.
