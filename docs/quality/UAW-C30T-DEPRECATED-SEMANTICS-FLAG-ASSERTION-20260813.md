# C30T deprecated semantics flag assertion

Date: 2026-08-13
Scope: C30T focused Social global-navigation verification only

## Observed failure

After the three C30T focused-test corrections were formatted, `flutter analyze` rejected the new C27D Social selected-state assertion. `SemanticsData.hasFlag` is deprecated and `SemanticsFlag` is not defined in the current Flutter test API.

No AAB build, upload, Play update, device mutation, backend write, Create write or Chat message occurred. C30T build/upload/install counters remain zero.

## Root cause

The assertion used a legacy remembered semantics API instead of the current repository-established `flagsCollection.isSelected` `Tristate` pattern.

## Bounded correction

Replace only the new C27D selected-state assertion with `flagsCollection.isSelected`, expecting `Tristate.isTrue` for the selected Social destination and `Tristate.isFalse` for the other destinations. Then run analyzer and the exact three focused tests before restarting qualification cycle 1.

## Resolution

The selected-state assertion now uses `flagsCollection.isSelected`. Analyzer passed with no issues and the exact C27D test passed.
