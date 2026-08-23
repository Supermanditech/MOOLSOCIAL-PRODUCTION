# UAW C10 navigation owner move unused imports

## Incident

The first C10B `flutter analyze` compiled the shared global-navigation refactor
but reported two warnings: `mool_theme.dart` was no longer used by the new
global owner, and the R14 test no longer used `mool_design_system.dart` after
its Ride assertion became a Social cold-launch assertion.

## Prevention

Source-owner moves and test assertion replacements include an immediate import
usage review. No focused widget or router pass is accepted until Flutter
analysis returns with zero warnings and errors.

No APK or OPPO mutation occurred.
