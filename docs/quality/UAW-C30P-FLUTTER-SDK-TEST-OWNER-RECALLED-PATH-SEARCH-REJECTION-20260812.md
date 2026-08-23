# C30P Flutter SDK test-owner recalled path search rejection

A read-only Flutter SDK search included a recalled path
`packages/flutter_tools/test/general.shard/flutter_plugins_test.dart` that does
not exist in the installed SDK. Ripgrep reported the missing path and exited
nonzero even though it returned useful matches from the other owners.

No file was changed. The compound result is rejected as complete SDK-test
evidence. Prevention: enumerate the exact matching SDK test filenames first,
then search only the existing owners and normalize a legitimate no-match exit.
