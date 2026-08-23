# C24C universal-intent Eat legacy-subaction rejection — 2026-08-09

The production-named Eat intent test enabled the legacy presentation and tried
the removed `sub-action-eat-order-food` intermediary. It therefore did not
exercise the accepted C24C native discovery Home.

REG655 moves the test to the real production route: a restaurant card opens
Order Food directly, Back restores discovery, Book Table opens directly, and
postponed Tiffin remains absent.
