# C30K-FIX1 Firebase codebase target-dialect rejection

- Scope: exact Dev-only Firebase deployment dry run.
- Result: the local predeploy build passed, then Firebase stopped with `No function matches given --only filters`; no cloud write occurred.
- Root cause: the short `functions:moolSocialContent` filter omitted the configured `provider` codebase segment.
- Prevention: use only the installed CLI's exact `functions:provider:moolSocialContent` filter for dry run and deployment; never broaden to all Functions.
