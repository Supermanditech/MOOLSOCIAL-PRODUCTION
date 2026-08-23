# C30Q integration-test usage filename-stdin search rejection

C30Q cycle 1 enumerated real integration-test filenames, then piped those
filename strings into `rg -l`. Ripgrep therefore searched the filename text on
stdin rather than the files' contents and the usage proof falsely failed.

The qualifier stopped before formatting, testing or release config-only. No
cycle output, APK, AAB, secret prompt or machine-state mutation occurred.

Prevention: run one bounded content search with the literal
`apps/mobile/integration_test` directory as the ripgrep owner, capture matching
file paths, normalize only exit 1 as no matches, and require at least one real
`package:integration_test/integration_test.dart` import.
