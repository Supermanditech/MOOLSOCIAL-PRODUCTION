# C30W Dart-format mobile main path miss

The first C30W formatting command ran from `apps/mobile` and supplied
`main.dart` instead of `lib/main.dart`. Dart reported the missing target while
formatting the three valid paths. The missing target was not altered, and no
build, upload, install, service action, device mutation or secret access
occurred.

Every subsequent mobile formatting command must use paths resolved relative to
`apps/mobile`, treat any missing-target diagnostic as failure regardless of
exit code, and use the exact bootstrap path `lib/main.dart`.
