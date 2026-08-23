# C29U Dev backend predeployment evidence

- Date: 2026-08-11
- Target: `moolsocial-dev-503018` only
- Project number: `760290687711`
- Organization: `1067591230270`
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- Ticket manifest SHA-256: `F7C3B42C7648A73C648500DAEACA4A64C6A3EC6DF03F1597818458496A9E7002`
- Sealed TypeScript source aggregate: `AB8D68286ADC79BB1B40BB742525239C8BE4687AAAF3C2CEC86206324F8A6C6E` across 107 files
- Protected installed OPPO identity: `1.0.0-r60.34`, version code `2026081134`; untouched during C29U

## Local qualification

- TypeScript typecheck: passed
- Functions build: passed
- Node tests: 495 passed
- Firestore and Storage emulator direct-client denial: 2/2 passed
- MVP scope gate: passed with C29U execution authority
- MVP delivery discipline lock: passed
- Permanent regression memory implementation gate: passed
- C29U sealed-source/rules/functions gate: passed

## Dev resource qualification

- Billing: enabled
- Required Functions, Run, Build, Artifact Registry, Firebase, Firestore, Storage, Secret Manager, App Check, Identity Toolkit and YouTube APIs: enabled
- Default bucket: `moolsocial-dev-503018.firebasestorage.app`
- Bucket location/class: `ASIA-SOUTH1` / `REGIONAL`
- Uniform bucket-level access: enabled
- Soft delete: seven days
- Direct client rules disposition: deny all
- `youtube-provider-runtime@...`: existing least-privilege YouTube runtime identity
- `social-content-runtime@...`: `roles/datastore.user`, `roles/firebaseauth.viewer`, `roles/firebaseappcheck.tokenVerifier`
- Social bucket grant: bucket-scoped `roles/storage.objectUser`; no project-wide Storage role
- Five required YouTube secrets: present as enabled Secret Manager versions; values were not read or copied
- Secret access: limited to the YouTube runtime identity

## Predeployment rollback anchors

| Function | Revision | Updated | Runtime identity | State |
| --- | --- | --- | --- | --- |
| `youtubeProvider` | `youtubeprovider-00032-xem` | `2026-07-26T08:04:43.834277802Z` | `youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com` | ACTIVE |
| `youtubeOAuthCallback` | `youtubeoauthcallback-00032-rul` | `2026-07-26T08:04:53.150557097Z` | `youtube-provider-runtime@moolsocial-dev-503018.iam.gserviceaccount.com` | ACTIVE |
| `moolSocialContent` | absent | pre-C29U | dedicated Social identity prepared above | not deployed |

Both existing YouTube revisions used Node.js 22, all traffic on the latest revision, the accepted Dev public-data review profile, owner/private upload capabilities disabled, and the registered HTTPS callback. The project-specific ignored dotenv deployment file contains only these non-secret flags and quota caps. Credentials and secret values remain exclusively in Secret Manager.

This evidence authorizes no Production deployment, promotion, provider/customer message, credential export, protected-runtime mutation or OPPO install. C29U is Dev-only.
