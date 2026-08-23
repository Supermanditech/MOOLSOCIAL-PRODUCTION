# C30K-FIX1 Dev content predeployment qualification

## Result

The Dev-only `moolSocialContent` redeployment is qualified. The authorized CLI
target is exactly `functions:provider:moolSocialContent`; YouTube functions,
rules, Hosting and every non-Dev environment remain excluded.

## Source and package gates

- Current source aggregate: 110 files,
  `42BFD0A47FD22C1E4142ED8E9CE85020BF958740057921C71250360CABA74C1E`.
- Dev corpus operator/runner TypeScript and compiled JavaScript, maps and
  declarations are explicitly excluded from the Firebase upload.
- `firebase-functions` is updated from 7.3.0 to the current 7.3.2 patch;
  Firebase's outdated-package warning is gone.
- Complete backend suite: 499/499 on the deployment runtime major, Node
  22.23.2. Evidence SHA-256:
  `5C3B6D095F66B543C0AAE4C23AB79B238405334EA9FCFB2E2D6F6A98A4A3AA38`.
- Final exact-target Firebase dry run: passed, 1.25 MB package, no outdated
  Functions warning. Evidence SHA-256:
  `D1D0439E382B1D8DE76736DE94F55E66333AE13349FE1A9DCE6DD1A5ADF168A0`.

## Cloud and security preflight

- Account/project/configuration: `hello@moolsocial.com`,
  `moolsocial-dev-503018`, `moolsocial-dev-fsc02d`.
- Billing and all required APIs: enabled.
- Current revision: `moolsocialcontent-00001-fef`, ACTIVE.
- Runtime identity: exact enabled Social service account with Datastore user,
  Firebase Auth viewer and App Check token verifier roles.
- Cloud Run `invoker-iam-disabled=true`; unauthenticated function request
  reaches application security and returns 401.
- Firestore and Storage direct-client probes return 403; rules remain deny all
  and are not being redeployed.

## Residual dependency advisory

`npm audit --omit=dev` reports one moderate transitive UUID advisory propagated
through the current latest `firebase-admin@14.2.0` Storage dependency. The
affected UUID v3/v5/v6 caller-supplied-buffer APIs are not directly imported or
used by MoolSocial. npm offers only incompatible/breaking dependency changes,
including an unsafe Firebase Admin downgrade, so no force-fix or major override
is admitted into this bounded deployment. There are zero high or critical
advisories.

## Protected boundary

The OPPO still contains rejected/preserved `1.0.0-r60.38+2026081238` with its
original first-install time. No APK build, install, launch, uninstall, data
clear or downgrade has occurred under this deployment ticket.
