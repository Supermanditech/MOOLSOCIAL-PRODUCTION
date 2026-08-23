# C30T gcloud reauthentication does not refresh Firebase CLI

Date: 2026-08-13

After `gcloud` was successfully reauthenticated as `hello@moolsocial.com`, a bounded Firebase Android-app inventory failed because Firebase CLI maintains a separate local session and reported that its credentials were no longer valid.

No deployment was attempted. Permanent prevention: prove Firebase CLI identity independently before every Firebase deployment and require founder-visible `firebase login --reauth` when that bounded read reports expired credentials.
