# Post-build host retry — generated package metadata restored

After the guarded APK wrapper completed, its clean-support restoration returned tracked generated Flutter support files to the repository checkpoint. The subsequent focused command incorrectly used `--no-pub`, so analysis and the widget test could not resolve the already declared `share_plus` dependency. Session-only tests that did not import that view completed; no source, APK or device result was invalidated.

Retry requirement: run `flutter pub get` after guarded build cleanup and before any `--no-pub` analysis/test command, then rerun the affected analyzer and focused test inventory.
