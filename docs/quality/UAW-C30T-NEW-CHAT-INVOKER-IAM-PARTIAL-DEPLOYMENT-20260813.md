# C30T new Chat invoker IAM partial deployment

## Observation

The exact Dev deployment targeted only:

- `functions:provider:moolSocialContent`
- `functions:provider:moolSocialChat`

Firebase successfully updated `moolSocialContent` and created `moolSocialChat`, then exited with code 2 because it could not set the newly created Chat service's implicit public invoker IAM policy. This is the same organization-policy interaction previously classified for the first `moolSocialContent` creation.

## Security model

MoolSocial does not add a public `allUsers` IAM binding. The accepted service model disables the Cloud Run invoker IAM check for the exact HTTPS service and enforces Firebase App Check plus Firebase Authentication inside the request handler. Direct Firestore and Storage client rules remain deny-all.

## Bounded recovery

- Do not repeat or broaden the Firebase deployment.
- Describe the exact created Chat service and the updated Content service.
- Apply `--no-invoker-iam-check` only to `moolsocialchat`.
- Prove both services are ready and use `social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com`.
- Prove unauthenticated requests reach the application boundary and return HTTP 401.
- Prove the excluded YouTube provider and OAuth callback revisions remain unchanged.

## Qualified recovery

The exact `moolsocialchat` service was recovered with Cloud Run invoker-IAM checking disabled. Read-only re-verification proved:

- ready revision `moolsocialchat-00001-yaf`;
- runtime identity `social-content-runtime@moolsocial-dev-503018.iam.gserviceaccount.com`;
- `run.googleapis.com/invoker-iam-disabled=true`;
- 100% traffic;
- application-level unauthenticated HTTP `401`;
- no change to `youtubeprovider-00036-qer` or `youtubeoauthcallback-00035-cir`.
