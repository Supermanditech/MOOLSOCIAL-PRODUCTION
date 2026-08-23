# C17E guessed Dart test config path rejection

Date: 2026-08-08

A predecessor host-cycle lookup appended a read of the guessed path
`apps/mobile/dart_test.yaml`. That file does not exist, so the aggregate lookup
is not accepted as complete configuration evidence even though the bounded
documents confirmed the historical three-shard 670-active boundary. C17E will
derive any test configuration path with `rg --files` and construct shard file
lists from verified inventory only.
