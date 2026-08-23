# C30T Chat retired-state cross-file patch-context rejection — 2026-08-13

An aggregate Chat correction placed a context block from `chat_flow_test.dart` under the navigation-test file update. The patch was rejected atomically and no source or test file changed.

Prevention: patch each source or test owner independently and re-read the exact target neighborhood before every cross-file test change.
