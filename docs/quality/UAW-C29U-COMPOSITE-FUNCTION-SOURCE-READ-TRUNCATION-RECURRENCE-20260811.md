# C29U composite function-source read truncation recurrence

- Date: 2026-08-11
- Scope: sealed function-source audit
- Result: read-only failure; no local source, cloud, build, device or app mutation

The predeployment inspection printed the complete large Functions entry point together with small manifests and exceeded the output limit. The returned excerpt is not used as complete source evidence.

The correction is to search exact exports, runtime identities and environment owners, then read only bounded line slices around those symbols. Small deployment manifests remain separate reads.
