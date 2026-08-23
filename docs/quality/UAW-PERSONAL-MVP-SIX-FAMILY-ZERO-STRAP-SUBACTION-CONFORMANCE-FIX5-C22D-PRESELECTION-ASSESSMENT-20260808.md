# C22D zero-strap subaction conformance preselection — 2026-08-08

## Customer outcome

Social, Buy, Eat, Ride, Book and Work show only individually clipped transparent medicine capsules over destination content. No full-width color, theme, tint, opacity, blur or background surface is allowed behind or between those controls.

## Actual owner and duplicate audit

The six families do not have six independent rail implementations. `MoolDestinationNavigationV2` owns the combined local/global bottom layout, `MoolLocalNavigationRail` owns every capsule cluster, `Screen04ContextTabs` adapts Social/Eat/Ride/Book/Work, and `BuyV2Screen` adapts Buy. Both Scaffolds already use `extendBody: true`. The apparent r60.20 strap is caused by the local rail consuming a full 52 logical pixels inside `bottomNavigationBar`, so the destination body is laid out above it and the transparent row exposes a flat Scaffold canvas instead of destination content.

No duplicate implementation is selected. C22D reuses these owners and changes the shared navigation composition so the local cluster is a hit-testable transparent overlay anchored immediately above the unchanged global rail. Only individual capsule filters may paint; the outer overlay remains paint-transparent. The obsolete diagonal wave is removed here and replaced by the authorized reverse-U bridge in C22E.

## Scope and gates

No screen, route, backend owner, persistent state owner, business rule or subaction is added. All existing 17 local outcomes remain one tap and at least 44 logical pixels. Build/install remain closed; r60.20 installed checksum identity stays preserved. C22C and the applicable delivery, scope, protected UI, App brand, copy, interaction and permanent-memory gates passed before selection.
