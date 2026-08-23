# C30S signing guard test stale-variable assertion

Date: 2026-08-13

The affected suite found that `platform_configuration_test.dart` expected the
old `releaseTaskRequested` name after C30S narrowed the guard to
`releasePackagingTaskRequested`. The production implementation is stronger;
the stale focused test must assert that exact bounded guard.
