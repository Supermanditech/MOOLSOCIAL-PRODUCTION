# C22G diagnostic wrong working directory and empty test list rejection

- Observed: 2026-08-08 while diagnosing the C22G required-suite rejection.
- Rejection: the command ran from `apps/mobile` but read
  `config/mvp-personal-capsule-system-regression-c22.json` as though it were at
  repository root. The read failed non-terminatingly, produced an empty test
  list, and `flutter test` began the entire mobile test tree.
- Disposition: the unintended full-suite runner was terminated after its exact
  Dart command line proved that no literal test paths were supplied. It is not
  qualification evidence.
- Prevention: resolve the repository root and contract to absolute literal
  paths, require exactly 14 derived mobile tests before `Push-Location`, and
  refuse Flutter invocation for an empty or wrong-count list.
