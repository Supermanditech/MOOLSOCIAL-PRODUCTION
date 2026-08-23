# Public brand-identity copy removal preselection assessment

Date: 7 August 2026
Ticket: `WEB-MVP-PUBLIC-BRAND-IDENTITY-COPY-REMOVAL-20260807`
Classification: `mvp_required`

## Founder authority and disclosed outcome

The founder directed removal of `SuperMandi Tech Pvt Ltd` from
`https://moolsocial.com/` across all pages where it appears and replacement
with `moolsocial.com`. Before implementation, Codex disclosed the customer
outcome, MVP classification, smallest complete scope, exclusions,
dependencies and verification plan. This document records that exact bounded
authority; it does not authorize any unrelated website, mobile, provider or
email action.

Customer outcome: every public MoolSocial page consistently identifies the
public brand as `moolsocial.com`, with no visible or structured-data occurrence
of the old company name.

The ticket is `mvp_required` because the live public identity, policy pages and
YouTube compliance page are launch and active-review dependencies. The work
corrects a founder-confirmed public identity requirement and does not add
optional product depth.

## Reuse and duplicate-search result

The canonical public origin remains `https://moolsocial.com/`. Firebase
Hosting continues to serve the existing `apps/web/public` owner from
`moolsocial-dev-503018`. The dynamic Next/Vinext metadata owners in
`apps/web/app` and the existing static-site regression file remain reused.

The separate `.openai/hosting.json` binding was inspected. It identifies the
older private MoolSocial Early Access Sites project at a ChatGPT Sites URL; it
is not the `moolsocial.com` custom-domain authority and must remain preserved.

Focused source and live-route searches found the old name in the existing home,
Privacy, Terms, Support, disconnect, delete-account and YouTube API page owners,
plus matching dynamic metadata and tests. No new screen, public route,
backend owner, service, database, component family or deployment project is
necessary. Disposition is reuse/configuration plus test-only acceptance.

## Smallest complete implementation

1. Replace the old company name with exact lower-case `moolsocial.com` in the
   existing public-page and dynamic metadata owners.
2. Update only the matching public-site regression expectations.
3. Run the existing public website tests, build and lint, plus an exact
   zero-occurrence scan.
4. Deploy only Firebase Hosting content from `apps/web/public` to project
   `moolsocial-dev-503018`.
5. Verify HTTP 200 and absence of the old name on every live route, then compare
   local and live HTML hashes.

## Explicit exclusions

- No new page, route, design, feature, persistence or backend owner.
- No Flutter, Android, iOS, Firestore, Functions or provider API change.
- No APK upload, publication, distribution or Android reviewer link creation.
- No YouTube capability, OAuth, scope, quota or compliance claim change.
- No Gmail send; mailbox assessment remains read-only.
- No DNS or Search Console change.
- No public-site access-policy change and no replacement of Firebase Hosting
  with the private Sites project.
- No commit, push, merge, branch switch, cleanup or deletion.

## Dependencies and test plan

Dependencies retained: exact remediation branch and HEAD, all dirty files,
permanent regression memory, active MVP scope/delivery locks, existing Firebase
Hosting authority, authenticated deployer availability, hosting-only target and
post-deployment source-to-live identity.

Robustness coverage includes exact static/dynamic copy parity, structured-data
copy, policy/support/account-control pages, YouTube review page, route status,
cache revalidation, deployment scope containment and live content identity.

Timeline impact is less than one day and remains within the founder-locked
60–75-day delivery window. The change reuses one public-web implementation and
one hosting release; it creates no duplicate implementation or build topology.
