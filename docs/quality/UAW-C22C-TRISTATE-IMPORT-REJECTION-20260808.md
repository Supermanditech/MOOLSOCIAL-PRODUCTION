# C22C Tristate import rejection — 2026-08-08

The C22C focused test compile rejected because the accepted `flagsCollection.isSelected` assertion referenced `Tristate.isTrue` without importing `dart:ui` `Tristate`. No runtime or device mutation followed the rejection. REG-20260808-526 records the cause and prevention.
