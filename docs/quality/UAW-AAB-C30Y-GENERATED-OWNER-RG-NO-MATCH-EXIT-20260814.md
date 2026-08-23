# C30Y generated-owner rg no-match exit

- Incident: `REG-20260814-2177-AAB-C30Y-GENERATED-OWNER-RG-NO-MATCH-EXIT`
- Scope: read-only recovery inventory

The command successfully printed the two changed owner hashes, then `rg --files` returned no candidate paths because generated/ignored files were not present in its inventory. The final filter's ordinary exit code 1 made the combined diagnostic appear failed. No file or release state changed.

The retry must use an explicit enumeration bounded to `C:\GUARANTEED OUTCOME` or handle no-match intentionally. It must compare hashes only and must not inspect credential or transient-file contents.

## Resolution

An explicit workspace-bounded filesystem enumeration completed successfully and found no duplicate exact-hash copies. FIX2 then reconstructed both owners deterministically: r60.47 release config-only reproduced `local.properties` at `915049047E3888292F4EE44F9B91C1D3338C6E1A1FA62117C8C9FD28424835D3`, and plugin generation reproduced `GeneratedPluginRegistrant.java` at `662E4302A2EEFA69AA59563ABC59C6FB3A3FAD58400DED741F706E4195B421B8`. No APK or AAB changed, and `pubspec.yaml` plus `pubspec.lock` remained exact.
