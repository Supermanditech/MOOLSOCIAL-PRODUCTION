# C30T stale C30S release-registrant cardinality — 2026-08-13

## Failure

The C30T readiness gate inherited the C30S expectation of 15 generated release plugins. The current dirty-tree registrant contains 16, so readiness failed closed before build qualification.

## Impact

- No AAB build authority was consumed.
- No external, upload, install or device mutation occurred.

## Required recovery

Enumerate the exact current plugin registrations and map each to an intentional release dependency. Only after excluding debug, integration and unused plugins may the successor allowlist and count be sealed.

## Audit result

The 16th registration was `dev.flutter.plugins.integration_test.IntegrationTestPlugin`, originating from the development-only `integration_test` dependency. It is not an allowed release plugin. The C30T qualifier must run the no-artifact release `--config-only` preflight first, prove that it restores the exact 15-plugin release registrant, and only then invoke static readiness and seal the source fingerprint.
