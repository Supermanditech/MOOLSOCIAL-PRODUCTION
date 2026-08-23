# C30Y preflight sealed source-owner mutation

- Incident: `REG-20260814-2176-AAB-C30Y-PREFLIGHT-SEALED-SOURCE-OWNER-MUTATION`
- Candidate: `UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE`
- Attempt disposition: failed closed before authority consumption
- Build/upload/install counts after exit: `0/0/0`

The founder entered all three hidden values successfully and the build hard gate passed. The wrapper then completed release config-only and fresh merged-manifest preflight. Before the single AAB authority was consumed, its second source-manifest check rejected the attempt because two qualified owners had changed:

- `apps/mobile/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
- `apps/mobile/android/local.properties`

The canonical 1,125-file manifest itself remains byte-exact at `713C86050A8EAE17F067B4B7043D3B46E4DEEC5ABC24BB939A193E1F65DAC190`; only those two current owners differ. The founder launcher reset hidden-input qualification and preserved `available_once`. It erased both transient founder files, and no secret was read by the agent.

Immutable first-attempt evidence remains under the C30X evidence root as `03-release-config-only.log`, `04-release-manifest-preflight.log`, `04a-merged-release-manifest.xml`, and `04b-release-manifest-merger-blame.txt`. Their contents are not needed to identify the source mismatch and are not inspected for credential values.

Before retry, a founder-authorized audit-finding FIX ticket must restore the two owners to their exact qualified bytes and make the preflight transaction restore all permitted generated-source mutations before the current-source assertion and on every exit. A new source manifest and two fresh identical cycles are required after the wrapper repair. No second launcher attempt is permitted before that qualification.

## Exact owner recovery

FIX2 preserved the first attempt's post-preflight owner bytes in separate evidence files, then reproduced both pre-attempt hashes without an APK, AAB or secret. Historical r60.47 config-only restored `apps/mobile/android/local.properties` exactly to `915049047E3888292F4EE44F9B91C1D3338C6E1A1FA62117C8C9FD28424835D3`. Deterministic plugin generation restored `GeneratedPluginRegistrant.java` exactly to `662E4302A2EEFA69AA59563ABC59C6FB3A3FAD58400DED741F706E4195B421B8`. Recovery logs are preserved as `fix2-reconstruct-r60-47-config-only-attempt-01.log` and `fix2-reconstruct-registrant-pub-get-attempt-01.log`.
