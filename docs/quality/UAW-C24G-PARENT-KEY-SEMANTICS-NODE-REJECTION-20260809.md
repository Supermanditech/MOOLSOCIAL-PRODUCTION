# C24G parent-key semantics node rejection — 2026-08-09

The first focused C24G semantics assertions read the keyed wrapper around each
shared primary button. Those wrapper nodes correctly reported no tap action;
the real descendant FilledButton owns the semantic tap. Layout and direct-route
tests had otherwise reached the targets.

The retry inspects the literal descendant FilledButton semantics under each
stable product key, while the stable parent key continues to own size and
scroll addressing. A noninteractive wrapper is never accepted as proof for an
interactive descendant or vice versa.
