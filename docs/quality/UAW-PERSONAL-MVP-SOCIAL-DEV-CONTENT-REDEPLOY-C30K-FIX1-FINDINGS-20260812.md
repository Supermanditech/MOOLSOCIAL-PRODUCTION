# C30K-FIX1 Dev content redeployment findings

## Founder outcome and ticket status

The post-r60.38 tickets are implemented at their authorized layers: C30I and
C30J are source-qualified, and C30K has three verified real Dev review personas,
36 persisted posts and 48 stored media objects. They are not yet fully delivered
because C30K's Firestore text-choice fix is newer than the deployed function and
C30I/C30J have not been exercised in a fresh successor APK.

## Deployment audit

- Exact account/project/configuration: `hello@moolsocial.com`,
  `moolsocial-dev-503018`, `moolsocial-dev-fsc02d`.
- Billing is enabled and all required Functions, Build, Artifact Registry, Run,
  Auth, App Check, Firestore, Storage, Secret Manager and YouTube APIs are enabled.
- Current `moolSocialContent` is ACTIVE on Node.js 22 as revision
  `moolsocialcontent-00001-fef`, using the exact Social runtime service account,
  512 MiB, 120 seconds, four max instances and concurrency twenty.
- The runtime identity is enabled and has only Datastore user, Firebase Auth
  viewer and App Check token verifier project roles. The regional Functions
  artifact repository exists.
- Cloud Run invoker IAM checking is explicitly disabled, matching the accepted
  C29U application-security model. An unauthenticated request reaches the
  function and receives HTTP 401 from its Auth/App Check boundary.
- Firestore and Storage unauthenticated direct-client probes both return HTTP
  403, so the already-deployed deny-all rules remain effective and do not need
  another rules write.

## Required bounded correction

The old C29U seal pins the pre-C30K function tree and cannot qualify the current
source. In addition, Firebase's function upload currently includes the compiled
non-HTTP Dev review-corpus provisioner and runner. The successor ticket excludes
those operator-only files, introduces a current-source deployment gate, runs an
exact dry run and then permits only `functions:moolSocialContent` in Dev.

YouTube functions, rules, Hosting, Production, credentials and the protected
r60.38 OPPO installation remain outside this deployment ticket.
