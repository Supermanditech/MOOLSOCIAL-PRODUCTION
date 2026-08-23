# C22H idle Gradle daemon misclassified as active build

- Observed: 2026-08-09 during the read-only C22H preselection machine audit.
- Initial result: a broad process probe reported one active build/test process.
- Exact process: PID 1192, `java.exe`, command
  `org.gradle.launcher.daemon.bootstrap.GradleDaemon 9.1.0`, started at
  2026-08-08 17:40:26. It is the long-lived idle daemon already admitted by
  the C21H prebuild record, not a Gradle client, wrapper build, Flutter build
  or Flutter test command.
- Root cause: the probe treated any Java command containing `gradle` as an
  active build and did not distinguish `GradleDaemon` from
  `GradleMain`/`GradleWrapperMain` client work.
- Permanent prevention: active-build evidence counts Java only when its exact
  main class is a Gradle client/wrapper command, and counts Dart/Flutter only
  when the executable command owns an actual `flutter build` or `flutter test`
  invocation. An idle daemon is reported separately but never counted as an
  active build.
- Authority effect: build/install stayed closed during diagnosis. No process
  was terminated and no runtime/device mutation occurred.
