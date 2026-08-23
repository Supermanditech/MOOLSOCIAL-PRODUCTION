# UAW C33J unresolved root pubspec search-path regression

- Regression: `REG-20260815-2489-C33J-UNRESOLVED-ROOT-PUBSPEC-SEARCH-PATH`
- Scope: read-only Firebase email-link dependency inventory.
- Failure: a combined `rg` lookup included a guessed repository-root `pubspec.yaml`, which does not exist. The command returned a path error after printing a separately requested exact source file.
- Impact: no source, reference, provider, email, build, Play or device state changed. The failed absence search supplies zero evidence.
- Prevention: resolve dependency manifests and optional search roots through `rg --files`, then search only proven owners and normalize a clean no-match separately.
