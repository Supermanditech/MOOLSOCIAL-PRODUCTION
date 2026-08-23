# C29N rewritten C16B exact edge-height assumption

Date: 2026-08-11
State: resolved; permanent prevention active
Regression: `REG-20260811-1233-C29N-REWRITTEN-C16B-EXACT-EDGE-HEIGHT-ASSUMPTION`

The migrated continuous Social suite passed all 13 tests. The first rewritten
C16B test then expected a compact edge cell to render exactly 44x58, while the
host layout rendered 44x57. The shared rail owner remains 58 pixels and the
control exceeds the required 44-pixel target. The successor test now separates
the token assertion from the rendered/semantic minimum instead of imposing an
unsupported exact child extent.
