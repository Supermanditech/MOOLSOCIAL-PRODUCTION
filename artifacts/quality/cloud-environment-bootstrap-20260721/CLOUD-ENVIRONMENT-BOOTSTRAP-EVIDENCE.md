# Cloud environment bootstrap evidence

Date: 21 July 2026

Scope: MoolSocial organisation IAM and Dev/Trial Firebase project only.

## Locked environment boundary

- Local Firebase emulators remain the zero-cost first test boundary.
- `moolsocial-dev-503018` is the separate real-service Dev/Trial environment.
- Screenwise Preview will be a Firebase App Distribution tester group inside
  Dev; it is not another backend.
- `moolsocial-staging-503018` remains uncreated and may receive only promoted
  candidates.
- Production remains uncreated and is never an experimentation environment.

## Organisation verification

- Organisation: `moolsocial.com`
- Authoritative organisation ID: `1067591230270`
- Direct admin-principal roles verified in organisation IAM:
  - Organisation Administrator
  - Project Creator
- Domain roles observed:
  - Billing Account Creator
  - Project Creator

An earlier attempted identifier, `1067591730370`, contained transposed digits.
It produced a `404 NOT_FOUND`/permission-style response during project creation.
That value is invalid and must not be reused.

## Dev/Trial creation

- Project ID: `moolsocial-dev-503018`
- Display name: `MoolSocial Dev Trial`
- Organisation: `moolsocial.com`
- Project number: `760290687711`
- Firebase CLI state: `ACTIVE`
- Firebase resources reported by CLI:
  - default Hosting site `moolsocial-dev-503018`
- Repository alias `dev` points to `moolsocial-dev-503018`.
- Repository `default` remains `demo-moolsocial-local`, so ordinary local
  commands do not silently target the real-service Dev project.

The corrected project-creation request created the Google Cloud project. The
same immediate transaction then returned `403 PERMISSION_DENIED` while adding
Firebase. Project IAM independently showed the MoolSocial admin principal as
Owner. Firebase console setup subsequently completed and displayed:
`Your Firebase project is ready`. A fresh `firebase projects:list --json`
observation then reported the project as `ACTIVE`.

Firebase documents that adding Firebase automatically creates a Browser API key
and auto-restricts it to Firebase-related APIs. A read-only console audit of the
generated key was not completed in this checkpoint because foreground user
input interrupted browser-control certainty. Treat the generated key's
application restrictions as unverified until a fresh credential audit records
them; do not create, expose or broaden any key meanwhile.

## Explicitly not completed

- No Staging project was created.
- No Production project was created.
- No billing account was attached to Dev/Trial at this checkpoint.
- No Maps, Places, Routes or other billable API was enabled.
- No Firebase Android, iOS or web app registration was created.
- No additional API key, OAuth client or social-provider secret was manually
  created after Firebase bootstrap.
- No App Distribution tester group was created yet.
- No production application file, accepted Screen 01–03 reference or Flutter UI
  was changed by this cloud bootstrap.

## Next guarded action

Before registering Firebase apps, use the existing production package identity
`com.moolsocial.app`, define Android and iOS credential restrictions, and obtain
the required action-time confirmation because app registration can create API
credentials. Configure Authentication and App Distribution only after that
guard is satisfied. Recheck billing status before any billable service.
