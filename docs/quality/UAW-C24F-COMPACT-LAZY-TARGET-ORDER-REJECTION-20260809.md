# C24F compact lazy-target order rejection — 2026-08-09

The first focused 320x568/140% Bus matrix listed `bus-to` before the earlier
swap control, then used a forward-only scroll helper to look backward after the
earlier element had been evicted. The runtime itself rendered without an
exception.

The corrected test measures the initial From field first and walks the literal
From → Swap → To → date-shortcuts → date-card order. The failed invocation
counts as no qualification cycle.
