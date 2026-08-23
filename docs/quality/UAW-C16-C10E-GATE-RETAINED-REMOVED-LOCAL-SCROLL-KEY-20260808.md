# C16 C10E stale local-scroll key rejection

After C10D passed, the complete C16 gate sweep stopped because the historical
C10E checker still required `moolsocial-local-navigation-scroll`. C16A removed
that wrapper as part of eliminating horizontal sub-action lanes.

The updated checker requires the shared adaptive-layout and compact-cluster
keys, `MoolLocalNavigationTokens`, selected semantics and finite accessible
motion, and explicitly rejects the old scroll key. C10E route-page ownership,
global-shell Hero continuity, Back behavior and reduced-motion requirements
remain unchanged.
