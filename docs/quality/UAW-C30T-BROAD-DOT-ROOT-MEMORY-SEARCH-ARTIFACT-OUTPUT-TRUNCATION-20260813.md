# C30T broad dot-root memory search artifact output truncation

- Regression: `REG-20260813-1967-C30T-BROAD-DOT-ROOT-MEMORY-SEARCH-ARTIFACT-OUTPUT-TRUNCATION`
- Ticket: `UAW-C30T-PRE-AAB-FEED-COMMENT-REPLY-DEAD-END`
- Result: the broad search output is rejected as evidence.

A regression-memory lookup searched the repository dot root and matched a
large artifact JSON file. The evidence channel truncated the result. The retry
must target exact config/docs owners or resolve filenames first.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
