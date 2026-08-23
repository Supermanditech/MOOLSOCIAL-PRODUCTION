# C24D backward-verification scroll-helper rejection — 2026-08-09

The destination selection itself passed, but the revised test reused the
forward-only lazy discovery helper to return to an earlier search surface after
the session rebuild. Its descendant `Scrollable` finder was empty and the test
threw before reading semantics.

The forward-only descendant-scrollable helper remains rejected for this
journey. The first proposed `ensureVisible` correction also assumed the target
was still constructed and was rejected under REG676. The final gate performs
bounded reverse dragging on the persistent keyed ListView until the earlier
destination owner is rebuilt, then uses `ensureVisible` and reads semantics.
