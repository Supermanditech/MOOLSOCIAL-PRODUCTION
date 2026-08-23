# C29I OPPO device-gate rejection

- Candidate: `UAW-PERSONAL-MVP-SOCIAL-SHORTS-PARITY-AND-CUSTOMER-COPY-OPPO-QUALIFICATION-C29I`
- Installed build: `1.0.0-r60.33` / `2026081133`
- Device: OPPO CPH2375, serial `2b3e0f71`, density 320 dpi
- Installed APK SHA-256: `8DF33A827C6C85C33B90D8BE46F1256ACD37975D387E7E9F402F27C5931953B3`
- Result: rejected; protected baseline not updated

The checksum-qualified in-place install and the primary Social journeys passed. Real provider-backed YouTube Home loaded, Shorts began at exported `y=0`, vertical swipe advanced to a different Short, the official video watch surface opened, Create exposed Post/Image/Image Poll/Quick Poll/Quiz/Carousel without internal commentary, Feed remained MoolSocial-owned, the six-control Social dock exported at least 47.5 logical pixels, and all six Mool switcher rows exported 56 logical pixels.

The shared non-compact Mool toggle on Chat exported bounds `[0,1396][720,1442]`: 46 physical pixels, or 23 logical pixels at 320 dpi. That is below the permanent 44 logical-pixel target and repeats the Android exported-semantics class that the C28D rejection prohibits.

The exact owner is the standalone non-compact branch of `MoolGlobalNavigationV2`. Destination rails already reuse `moolAndroidExportedSemanticsClearance`; the Chat bottom-navigation stack reaches `MoolGlobalNavigationV2` directly and therefore misses that shared clearance. The successor must reuse the existing helper for standalone non-compact placement without double-applying it to compact destination rails.

The installed r60.33 identity and all C29I evidence remain preserved. Build count is one, install count is one, and no uninstall, data clear, downgrade, second build, second install or baseline promotion occurred.
