# C20B third focused-test excluded-semantics finder rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SUBACTION-DISCLOSURE-AND-OVERFLOW-AFFORDANCE-FIX3-C20B`

## Preserved rejection

The third focused C20B invocation passed the normal/reduced-motion case, the
session-only restoration case and the complete overflow case. All six family
cases passed their `48.0` geometry, exact Hide/Show action semantics, tap,
collapse and route-nonmutation assertions, then rejected one final expectation:
`find.bySemanticsLabel('<Family> options')` still found the declarative
`Semantics` widget after collapse.

The production owner wraps the collapsed local rail in
`ExcludeSemantics(excluding: true)` and `IgnorePointer(ignoring: true)`. A
widget finder can still inspect the excluded descendant widget and its declared
label; that does not mean the descendant participates in the accessibility
semantics tree. The failed assertion conflated widget-tree discoverability
with active semantics-tree inclusion.

No build, install or OPPO mutation occurred.

## Retry rule

The focused test must assert the collapsed region's zero layout height and the
active exclusion/ignore wrappers. It must not treat discovery of a declarative
Semantics widget beneath `ExcludeSemantics` as an accessibility leak.
