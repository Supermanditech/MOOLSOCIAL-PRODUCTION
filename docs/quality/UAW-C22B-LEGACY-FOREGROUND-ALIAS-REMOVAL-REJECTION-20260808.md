# C22B legacy foreground alias removal rejection

The first C22B analysis found three existing tests that still compile against `MoolLocalNavigationTokens.lightForeground`. Removing that name together with the visual light/dark split was premature. C22B retains source-compatible light/media aliases that both resolve to `neutralForeground`; runtime styling remains one universal neutral capsule.
