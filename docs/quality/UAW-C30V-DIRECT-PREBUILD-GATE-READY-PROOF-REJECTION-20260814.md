# UAW C30V direct prebuild gate ready-proof rejection — 2026-08-14

## Incident

After both fresh C30V r60.47 qualification cycles passed with the same stable-source fingerprint, a direct invocation of the C30V AAB gate in `build` phase failed closed with `single build is not ready or final source/preserved-service proof differs`.

No founder prompt was opened. No AAB, APK, upload, Play release, install, backend deployment, Hosting deployment, or OPPO mutation occurred. Counts remain `0/0/0`; r60.46 remains unuploaded and OPPO remains Play-installed r60.45.

## Root cause and recovery

The direct diagnostic invoked the build phase too early. `secretDefineFileQualifiedByFounder` and `googleServicesFileQualifiedByFounder` are intentionally false after qualification. The visible founder launcher alone sets both flags true after validating the two hidden inputs, immediately before it invokes the build wrapper; its `finally` block resets them if no build is consumed.

No gate or stable sealed source required repair. The regression registry and this incident document are explicitly excluded from the C30V stable-source manifest, so the two identical cycles remain valid. Recovery is to launch only the exact qualified visible founder wrapper and let it own the transient runtime qualification and build-phase gate.
