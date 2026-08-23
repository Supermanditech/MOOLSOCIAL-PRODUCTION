# C30K Flutter Feed test-path guess rejection

## Finding

The read-only Flutter coverage audit included a remembered C29Z-derived test filename without first confirming it in the repository. Two real test files returned useful matches, but the combined command exited non-zero and is not accepted as a passed audit.

## Disposition

Rejected and registered as `REG-20260812-1405-C30K-FLUTTER-FEED-TEST-PATH-GUESS-REJECTION`.

## Permanent prevention

Discover exact Flutter test paths from `rg --files` and use only those paths in follow-up searches. Never construct a test filename from a ticket identifier or prose description.
