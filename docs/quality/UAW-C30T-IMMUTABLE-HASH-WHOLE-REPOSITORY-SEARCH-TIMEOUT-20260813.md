# C30T immutable hash whole-repository search timeout

Date: 2026-08-13

The first lookup for the immutable `platform_configuration_test.dart` checksum searched the entire large dirty repository and timed out without returning a result.

Permanent prevention: inspect `approved-references/manifest.json` and `scripts/check-approved-ui-locks.ps1` first, then search only an exact referenced evidence directory if a content owner is still needed.
