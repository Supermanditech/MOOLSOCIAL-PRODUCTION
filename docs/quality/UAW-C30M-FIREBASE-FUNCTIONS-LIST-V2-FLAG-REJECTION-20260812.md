# C30M Firebase Functions list v2-flag rejection

- ID: `REG-20260812-1441-C30M-FIREBASE-FUNCTIONS-LIST-V2-FLAG-REJECTION`
- Date: 2026-08-12
- Scope: read-only Firebase Functions inventory
- Result: CLI option rejected; no cloud mutation, source mutation, build, install or device mutation occurred

The installed Firebase CLI rejects `functions:list --v2`; that generation flag
belongs to the installed gcloud Functions inventory surface, not this Firebase
command. C30M retries the Firebase JSON inventory without `--v2`, checks the
immediate exit status and projects only the three authorized function metadata
records. An option rejection is never interpreted as empty deployed state.
