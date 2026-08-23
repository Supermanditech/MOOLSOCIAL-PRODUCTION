# UAW Personal MVP Social Dev review personas and content C30K findings

## Founder outcome

Create three real Dev Firebase Auth review personas and two posts per persona for every supported MoolSocial Feed format: text, image, carousel, four-choice Image Poll, four-choice Quick Poll and four-choice Quiz. The result is 36 persisted posts that Flutter reads through the authenticated MoolSocial content contract. Deployment remains held.

## Reuse and duplicate audit

- The Flutter owner is `AuthenticatedSocialContentGateway`; it requires a Firebase ID token and Firebase App Check token and decodes only server-returned records.
- `SharedSession` loads, publishes and interacts through that gateway. It has no accepted local fallback when the endpoint is unavailable.
- `SocialContentService` already validates the six requested formats, image bytes, sizes, choice count and Quiz answer.
- `FirestoreSocialContentRepository` already owns idempotent post writes, server-side media persistence, download URLs, cursor ordering and per-user interaction state.
- The function author resolver already derives exact author name and handle from Firebase Auth, so client-supplied identity is not trusted.
- Direct client Firestore and Storage rules are deny-all.
- No existing Auth/review-corpus provisioner was found under the verified scripts, backend source or config owners.

## Current Dev runtime

Read-only Google Cloud inspection on 2026-08-12 found:

- project `moolsocial-dev-503018` under authenticated account `hello@moolsocial.com`;
- `moolSocialContent` state `ACTIVE`;
- ready revision `moolsocialcontent-00001-fef`;
- runtime `nodejs22`, service account `social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com`;
- exact Firebase storage bucket `moolsocial-dev-503018.firebasestorage.app`;
- no backend, rules, Auth, Firestore or Storage mutation was performed by this audit.

## Authority gate

The installed gcloud user session is valid for read-only Cloud inspection, but Firebase Admin Application Default Credentials are not currently available to the local server-side runner (`app/invalid-credential`). C30K therefore authorizes source and test implementation first. External Dev Auth, Firestore and Storage writes remain held until:

1. the deterministic runner and focused tests are source-qualified;
2. the founder completes the visible `gcloud auth application-default login` flow without sharing a password or token;
3. a bounded identity/project probe succeeds without printing credentials;
4. the ticket and MVP scope gate explicitly transition external Dev data writes to authorized.

## Safety disposition

Review personas will be disabled, passwordless and clearly named `MoolSocial Community Preview`. The runner will create only missing deterministic UIDs, reject any existing identity mismatch, never enable/update/delete accounts, use deterministic post idempotency keys, and default to dry-run. It will not expose an HTTP function or relax client rules.
