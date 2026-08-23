# C22C SemanticsFlags contains assumption rejection

`flagsCollection` is a typed `SemanticsFlags` object, not a Set. Workspace examples prove the correct assertion is `flagsCollection.isSelected == Tristate.isTrue`. The test removes the unnecessary `dart:ui` enum import and uses that established API.
