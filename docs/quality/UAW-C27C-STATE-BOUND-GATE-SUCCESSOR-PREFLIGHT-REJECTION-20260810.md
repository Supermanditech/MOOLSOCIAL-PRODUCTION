# C27C state-bound gate successor preflight rejection

During C27D gate construction, the completed C27C switcher gate was found to
require the global scope ticket to remain C27C and runtime authorization to
remain open. C27D is intentionally test/gate-only, so that stale selection
check would falsely reject an unchanged, completed switcher contract.

The C27C gate is migrated to require exact scope and runtime authorization only
while its manifest is active. Once complete, it validates the completed ticket
and durable source/test contract without pinning global scope to C27C. Build
authorization remains closed in either state.
