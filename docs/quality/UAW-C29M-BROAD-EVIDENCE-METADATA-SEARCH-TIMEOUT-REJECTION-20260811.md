# C29M broad evidence-metadata search timeout rejection

- Date: 2026-08-11
- Scope: resolving non-secret verifier identifiers
- Result: read-only timeout; no cloud, source, build, device or app mutation

The lookup combined several broad historical trees, including all artifact evidence, and timed out before yielding results. The C29M ticket already points to the exact C29L deployment-metadata audit and source manifest, so the broad scan was unnecessary.

The correction is to read only those exact owners and the reviewed deployment manifest. Historical artifacts are not searched recursively unless a bounded direct owner proves insufficient.
