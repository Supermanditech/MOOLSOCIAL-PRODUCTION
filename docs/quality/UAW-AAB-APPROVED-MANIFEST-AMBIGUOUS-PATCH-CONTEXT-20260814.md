# AAB approved-reference manifest ambiguous patch context

Date: 14 August 2026
Scope: Screen03 v4 test-only lock reconciliation

The first approved-reference manifest patch used repeated generic JSON fields
as anchors. It changed the Screen01 v3 status instead of Screen03 v3 and placed
the new Screen03 v4 object outside the intended lineage position. JSON parsing
still succeeded, but the protected manifest state is not accepted and no UI
lock or release claim may use it.

The correction uses the exact screen ID, version, status and root block,
restores Screen01 v3, supersedes only Screen03 v3, then proves exactly one
production-accepted version for each locked Screen01–03. No AAB, Play/OPPO
action, deployment or secret access occurred.

## Resolution

The protected manifest now has exactly one production-accepted version for
each locked Screen01–03. Screen03 v4 is active and v3 is immutable superseded
history. Every v4 metadata hash and all twelve locked owner hashes pass.
