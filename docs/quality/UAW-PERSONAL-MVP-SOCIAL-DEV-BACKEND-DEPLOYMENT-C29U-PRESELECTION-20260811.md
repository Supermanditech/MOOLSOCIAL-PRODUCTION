# C29U Dev Social backend deployment preselection

Date: 2026-08-11

Branch/HEAD:
`remediation/prototype-conformance-2026-07-20` /
`f6dfe7587aa02d782e94282d14af8bafff48ded0`

## Founder authorization

The founder explicitly authorized deployment of the sealed
`youtubeProvider`, `youtubeOAuthCallback` and `moolSocialContent` functions,
the required deny-all direct-client rules, the bounded supervised private
upload proof, and a later separately machine-qualified successor APK install
on OPPO. The founder also authorized required Dev GCP/Firebase access.

## Exact selected outcome

C29U is `mvp_required`. A founder-supervised Dev release operator deploys only
the already sealed Social backend owners to `moolsocial-dev-503018` and proves
their identity, least privilege, denial boundaries, health and rollback before
any APK build.

The ticket reuses the three existing function exports, existing Firestore and
Storage deny-all rules, existing runtime service accounts, Auth/App Check
contracts and tests. It adds no customer screen, route or backend owner.

## Exclusions

No Production or Staging action, provider submission/message, public or
unlisted upload, secret/token/key value read or copy, APK build/install,
uninstall, data clear, downgrade, commit, push, payment or reference mutation
is authorized by C29U.

The dependent C29M private-upload proof and C29V APK/OPPO candidate remain
separate atomic acceptance units.
