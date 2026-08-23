# C30S stale OPPO UI bounds opened composer — 2026-08-13

## Bounded event

A prior hierarchy placed the YouTube **Try again** node at `[228,892][492,988]`. After intervening screenshot and evidence-inspection steps, an ADB tap used its former centre. The result hierarchy showed the MoolSocial composer, including **Close composer**, post type actions and **Post**, rather than a YouTube retry result.

No post content was entered and no Create write was attempted.

## Prevention

Every later device action must use one immediate atomic sequence:

1. Prove `com.moolsocial.app/.MainActivity` focus.
2. Dump a fresh hierarchy.
3. Require exactly one target node by semantic text or description.
4. Derive the centre from that same fresh node.
5. Tap once.
6. Recapture and classify the resulting screen.

Previously captured coordinates are evidence only and must never be reused for a later tap.
