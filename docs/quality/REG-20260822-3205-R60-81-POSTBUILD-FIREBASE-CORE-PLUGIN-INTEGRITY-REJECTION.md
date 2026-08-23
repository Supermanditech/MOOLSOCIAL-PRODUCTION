# REG-20260822-3205 — r60.81 post-build Firebase Core plugin-integrity rejection

## Incident

The authorized r60.81 release APK assembled successfully, but the final
production plugin-integrity gate rejected it because
`io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin` was not found.

## Impact

- Authorized build actions consumed: `1`
- Total recorded build attempts including the earlier resource failure: `2`
- Qualified or sealed APKs: `0`
- OPPO actions: `0`
- Private/provider actions: `0`

## Root cause

The post-build gate searched unmapped `apkanalyzer` class output for the
original Firebase Core plugin name, while R8 had renamed that class. The
current mapping-aware, defined-class output proves the generated registrant,
Firebase Core and `MainActivity` are present and `integration_test` is absent.

## Permanent prevention

Require mapping-aware, defined-only multidex inspection for every minified APK
and mapped-DEX inspection for every AAB before copy, seal or sideload. Exercise
positive, missing-class, missing-mapping and forbidden-`integration_test`
fixtures before every build workflow.
