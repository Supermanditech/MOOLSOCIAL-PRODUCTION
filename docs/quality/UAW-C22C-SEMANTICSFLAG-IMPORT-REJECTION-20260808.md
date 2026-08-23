# C22C SemanticsFlag import rejection

The first C22C test compilation rejected `SemanticsFlag.isSelected` because the test omitted `dart:ui`. No later verification is counted. The correction imports only `SemanticsFlag` from `dart:ui` and reruns the focused suite.
