# C30Y FIX2 mutation-safe release preflight source transaction completion

- Ticket: `UAW-C30Y-FIX2-MUTATION-SAFE-RELEASE-PREFLIGHT-SOURCE-TRANSACTION`
- Parent: `UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE`
- Disposition: implementation complete; fresh post-FIX2 source manifest and two identical qualification cycles required before build authority can return
- Build/upload/install counts: `0/0/0`
- Founder hidden inputs retained: no
- AAB produced: no

The first founder-input attempt remains preserved and failed closed before authority consumption because release preflight changed two sealed generated owners. Its config-only log, merged-manifest log and XML/blame evidence remain immutable. The post-attempt owner copies and deterministic reconstruction logs also remain preserved.

FIX2 now snapshots the exact qualified bytes of `GeneratedPluginRegistrant.java` and `android/local.properties` before any source-mutating preflight. It restores both owners in a `finally` path before authority consumption and again after the single appbundle path, then requires the full source manifest to match. The restore helper rejects an escaped path, a missing owner or snapshot, a non-uppercase/incorrect expected hash, and any result whose exact SHA-256 differs from the qualified snapshot.

Current reconstructed qualified-owner seals:

- `662E4302A2EEFA69AA59563ABC59C6FB3A3FAD58400DED741F706E4195B421B8` — `apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
- `915049047E3888292F4EE44F9B91C1D3338C6E1A1FA62117C8C9FD28424835D3` — `apps/mobile/android/local.properties`

Implementation seals at completion:

- `F5BC9B99DD78198DA7E42039AE4DE30861B36516147700A91DE158A1E3572DF1` — single-AAB wrapper
- `F5118CEADA5787BB51CFD51D108C6F9B59E9612D9F49FC9F899F9E8FD2A82AFF` — exact-owner restore helper
- `ABBC9C784ED23A96DD2D4955DAD0187FA7698E0A41136FB915CD800D14F9A324` — FIX2 static/behavioral checker
- `DA9FABD71BD30899587B29BDFBD4835B4A178A7D6672726F0CCDACAD0EF98EBD` — FIX2 ticket

The checker passed on PowerShell 7 and Windows PowerShell with two snapshots, preflight restoration, postbuild restoration, a positive exact-byte restore, a negative hash rejection, and exactly one appbundle invocation. MVP scope and delivery discipline then passed after returning the active ticket to C30Y with build authority still false.

No launcher retry is permitted until a fresh post-FIX2 manifest and two complete identical regression cycles pass and are bound into C30X state and aggregate. The next founder-input run must allocate the unoccupied attempt-2 evidence slots and must not overwrite or reuse the preserved first-attempt files.
