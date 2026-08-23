# C22C deprecated semantics hasFlag rejection

All focused assertions passed, but full analysis rejected `SemanticsNode.hasFlag` as deprecated. The test now checks `flagsCollection.contains(SemanticsFlag.isSelected)` and must pass full analysis before C22C completes.
