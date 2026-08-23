# C24B3 connected cyclic-route duplicate page-key rejection — 2026-08-09

The Work intent journey opened Workspace from Earn Today through the connected
chooser, then selected Earn Today again. The second switch attempted to push a
route already beneath the current page and GoRouter rejected duplicate page
keys and a duplicated root Navigator GlobalKey.

REG651 adds the missing cyclic A-to-B-to-A acceptance. Global destination
switching must not duplicate stack keys, navigate through Home or lose the
single launcher. Modal dismissal remains unchanged.
