# UAW-C33F FIX3 interactive reauthentication removed transient debug evidence

- Recorded at: `2026-08-15T10:42:52.4352478Z`
- Regression: `REG-20260815-2396-C33F-FIX3-INTERACTIVE-REAUTH-REMOVED-TRANSIENT-DEBUG-EVIDENCE`
- Scope: Firebase authentication prerequisite for the authorized SHA-1 repair.

The interactive reauthentication was launched with the production repository as its working directory. On successful exit, Firebase CLI removed the pre-existing untracked `firebase-debug.log` referenced by regression 2341. The file was not tracked, is no longer present, and its contents were never inspected. It cannot be truthfully restored.

The durable sanitized 2341 quality document remains. The missing transient pointer is removed rather than replaced with fabricated evidence. Future interactive Firebase authentication must run from a dedicated temporary directory outside the production repository.
