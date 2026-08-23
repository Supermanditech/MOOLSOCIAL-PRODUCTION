# REG3092 — r60.80 APK missing plugin registrant and Firebase Core plugin

- Date: 2026-08-21
- Status: candidate rejected; successor builds blocked
- Rejected version: `1.0.0-r60.80+2026082180`

## Exact diagnosis

The installed checksum-matched r60.80 stage receipt passed the Flutter first
frame, then failed immediately at `firebase_initialize`. APK dex inspection
proved all of the following without reading any private value:

- `io.flutter.plugins.GeneratedPluginRegistrant`: absent;
- Firebase Core plugin class: absent;
- integration-test plugin class: absent.

The AGP 9 source-set repair excluded the entire Java source root to avoid the
stale test-only registrant. That also removed the only production plugin
registration owner. Release shrinking then removed plugin classes as
unreferenced, so Firebase had no platform channel.

## Mandatory prevention

- restore a durable production `GeneratedPluginRegistrant.java`;
- remove only the `integration_test` registration block;
- unignore the exact registrant so it participates in source manifests;
- remove the Java-root exclusion;
- source gates require the production registrant and Firebase Core reference
  while forbidding integration-test references;
- artifact qualification must inspect dex and require both the registrant and
  Firebase Core plugin class before any install;
- authentication remains blocked until the installed cold-start stage receipt
  reaches `normal_app=passed`.
