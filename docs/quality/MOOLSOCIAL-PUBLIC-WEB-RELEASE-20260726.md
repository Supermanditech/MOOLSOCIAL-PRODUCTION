# MoolSocial public web release — 26 July 2026

## Founder approval and authority

- Founder-approved browser source: `http://127.0.0.1:4174/`
- Durable production source: `apps/web/public`
- Firebase project: `moolsocial-dev-503018`
- Firebase Hosting site: `moolsocial-dev-503018`
- Public domain: `https://moolsocial.com/`
- Firebase URL: `https://moolsocial-dev-503018.web.app/`
- Static asset release identifier: `20260726-2`

`apps/web/public` is the canonical, restorable copy of the approved MoolSocial
public website. A second repository or parallel public-web source must not be
created. Future public releases must begin from this directory and preserve
the legal, support and account-control routes unless a later founder decision
changes them.

## Release verification

- Production web build and automated release suite: 5/5 passed.
- Public routes `/`, `/privacy`, `/terms`, `/support`, `/disconnect` and
  `/delete-account` returned HTTP 200.
- CSS and JavaScript returned HTTP 200 with correct content types.
- Local canonical files and `https://moolsocial.com` matched byte-for-byte:
  19/19 files.
- Public HTML requests versioned CSS and JavaScript using `?v=20260726-2` to
  prevent a prior cached stylesheet from being applied to newer markup.
- The public domain resolved to Firebase Hosting and returned the MoolSocial
  page over HTTPS.

The public marketing site is hosted in the approved Dev project pending
creation and written approval of the separate Production Google Cloud/Firebase
project. This release does not alter Functions, Firestore, Authentication or
provider integrations.

## SHA-256 manifest

```text
8c97d6c36f460f3a6fb1274666d1e027bbcd0e08b95358dca68c398349b72285  app-preview-create-earn.webp
9b69e8bf9f7f61e9fcaf396c17bda12971e86241313e479ca8d44f63000de1fa  app-preview-for-you.webp
a6f61ba7d598e4fccbbf177915eb238cef35d35ea33b716cb8a3d44ef336b322  app-preview-shop-deliver.webp
676ab89e66e75e023e04cd0590485e1ae6f2120ac555a9b516436b2450c5368d  app-preview-social-video.webp
4f0923f776621389534a6bf1c9c6b6a6fbe29de18eaebc8d84a1e82c7a222fc3  app-preview-universal-actions.webp
04f5e002a2032a26609502fe79d93b6d7009692803ad6029b05492ca72fa2ab8  app-preview-work-grow.webp
3f2d3a1ed40dff9c142469b0eedeaf76d52e49d780b624c4761d3282fd34ac9a  delete-account/index.html
0b8b524bf01bc19a0a7392d579ad4884ebe77b0d2fb94af17fee3bf13ae45741  disconnect/index.html
967499cfc6872d2d8f0b51a8eb3a57dba47c89815fde57dd0a13e5c1a42c7590  index.html
1e1fe655ef3d85b7e3cf89ac1ce85e04dcaea62237f3011d50961b9018e49467  moolsocial-workspace-logo.png
3d41a1c75c0e0823c09cfbb634fb6ce72ff4d133f4ad3bc865f03e143ead4a03  moolsocial-workspace-logo.svg
a46653bc4a1da1a7e1d3df45a306dc28040ba1d24ad2afff9a43c6fc28e77217  og-2026-10-24.png
1f62adf3b158adf72093f0a687c75139ecc460b2e7969603353cd42cf40922cd  og.png
f6effbe1f5321c7625f450eeed9ee0bbfc72eaf4b33696aa60b52446a7ace5b0  privacy/index.html
65f866a8f53af89254dee36cef032848f8ffd1d780b7e39f4a7f9e2410d5cff4  site.css
8b092a3b65a111abb87762a434cc9b0bcb61e4096c445d880595f0919cc1e7d4  site.js
3c0149f26168b5fe0f43e68664abe40341a6443b3cd435d18a73e12f64f8b600  social-linkedin.png
c467098b951c8e8b1dab463b90e4103493784b802fd172bb225f6e7dbb715ad8  support/index.html
a62a022a480aa56e975868e0d236d8507f63de176b6e95213abb4acfcef5916e  terms/index.html
```

## Restore and redeploy

From the repository root, run the web release tests and deploy Hosting only:

```powershell
npm --prefix apps/web test
firebase deploy --only hosting --project moolsocial-dev-503018
```

Do not broaden this command to Functions, Firestore or other Firebase
resources.
