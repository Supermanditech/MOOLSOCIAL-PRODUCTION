# C10C reachable legacy BuyPageScaffold navigation

The initial C10C inventory covered `ui_v2/buy` but missed the production `/app/buy/grocery` and nested order routes. Their shared `BuyPageScaffold` still rendered a Buy-owned `BuyBottomDock` with `buy-dock-*` keys and a top `buy-back` arrow. This is a real production navigation owner and blocks C10C until it uses the global dock, local header actions and system Back.
