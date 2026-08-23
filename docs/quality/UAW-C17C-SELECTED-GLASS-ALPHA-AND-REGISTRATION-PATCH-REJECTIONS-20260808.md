# C17C selected-glass alpha and registration-patch rejections

Date: 2026-08-08

The second C17C focused run proved Buy but rejected Social's selected Shorts
glass at alpha `.630745...`, above the contract's `.58` media base and the
background-visibility ceiling. `Color.alphaBlend` increased aggregate opacity
when tinting the selected base. The shared token must interpolate RGB toward
the accent while preserving the base glass alpha exactly for selected and
pressed states.

The first registration patch for that finding was itself rejected atomically
because it used an inexact remembered line-wrap context in the prior evidence
document. No registration or memory hunk from that patch was admitted. This
new evidence file and exact registry-tail context are used before retrying the
runtime correction.
