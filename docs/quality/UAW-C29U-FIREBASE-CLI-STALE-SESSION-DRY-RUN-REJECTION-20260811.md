# C29U Firebase CLI stale-session dry-run rejection

- Date: 2026-08-11
- Command disposition: exact-target dry run rejected before deployment
- Cloud mutation: none

The Firebase CLI independently rejected its cached credential as no longer valid. The Functions predeploy TypeScript build completed successfully, after which the CLI stopped while checking the Storage API. No rule or function deployment began.

`gcloud` and Firebase CLI authentication are separate local sessions. The correction is one founder-visible `firebase login --reauth` flow, with all password, consent and token handling kept in the Google/Firebase browser path. The exact dry run must then pass before any deployment command is permitted.
