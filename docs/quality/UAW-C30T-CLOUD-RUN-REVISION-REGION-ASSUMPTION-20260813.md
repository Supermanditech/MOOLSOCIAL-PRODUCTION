# C30T Cloud Run revision region assumption

Date: 2026-08-13

The read-only provider reconciliation attempted to describe the four exact Cloud Run revisions in an assumed `asia-south1` region. The first read failed, and its native diagnostic had been suppressed. No Cloud Run state changed and the result is rejected.

Permanent prevention: derive the exact region from repository evidence or a bounded project revision inventory, retain failure diagnostics, then describe one exact revision at a time and report only revision, service, region and Ready status.
