# C29U broad IAM-owner search timeout rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1294-C29U-BROAD-IAM-OWNER-SEARCH-TIMEOUT-REJECTION`

After the Dev project showed the Social runtime service account and Firebase
application bucket were absent, a search for role precedent traversed broad
documentation, configuration and backend scopes. It timed out without usable
output and was rejected before any IAM or bucket mutation.

The retry resolves the literal C29P/C29U ticket and evidence filename family,
then reads one exact owner. IAM permissions are also verified from the official
gcloud role descriptions before the least-privilege account is created.
