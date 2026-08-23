# C24B3 Social wordmark unused-import rejection — 2026-08-09

After removing the redundant Social header wordmark and identity line, the affected-source analyzer reported `journey_frame.dart` as unused. Its last consumer in `universal_shell.dart` was the removed `PrototypeIdentityLine`.

The import is removed and the affected Social/global-navigation source analyzer must return no issues.
