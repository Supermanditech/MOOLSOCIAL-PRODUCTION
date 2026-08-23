# C29U resumed-inspection composite and unbounded recurrence

- Date: 2026-08-11
- Scope: local C29U continuation
- Result: no cloud, build, device or app mutation occurred

The resumed inspection combined a full dirty-tree listing with a guessed registry filename. The listing overwhelmed the useful output and the later registry read failed. A subsequent collection-property guess produced an empty result.

The correction is durable: use `config/codex-development-regression-registry.json`, read its `entries` collection, keep branch/HEAD/status checks scalar and separate, and never compose full dirty-state output into a deployment-evidence read.
