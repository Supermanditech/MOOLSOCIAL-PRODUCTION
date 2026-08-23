# Web MVP public discovery and YouTube review-access remediation ticket

Prepared: 5 August 2026
State: **DISCLOSED AND AUTHORIZED — ACTIVE**
Ticket: `WEB-MVP-PUBLIC-DISCOVERY-AND-YOUTUBE-REVIEW-ACCESS-REMEDIATION`

## Customer outcome

A customer, partner, search crawler or compliance reviewer can open the
canonical MoolSocial public website without authentication, understand who
MoolSocial is, find its public launch and policy information, and reach a
truthful explanation of the product's YouTube API boundary. Google Search
Console can verify the domain, accept the sitemap and receive indexing
requests, while the YouTube review team receives a direct answer and a safe
path to inspect the current Android review build.

Google ultimately controls crawling, indexing and ranking. This ticket can
make the site eligible, verifiable and explicitly submitted; it cannot promise
an immediate search result or ranking.

## MVP classification and reason

Classification: `mvp_required`.

The 45-day launch authority includes public marketing pages in Days 35–39.
Public accessibility, truthful company identity, compliance review access and
search-engine discovery are launch blockers rather than optional product
depth. The YouTube review is also an active provider/compliance dependency for
the already bounded Android Social launch slice.

## Smallest complete scope

1. Preserve `https://moolsocial.com/` as the canonical public origin and the
   existing Firebase Hosting Dev/Trial site as the current custom-domain
   authority.
2. Diagnose and, where authenticated access permits, repair the missing
   `www.moolsocial.com` host with one canonical redirect to the apex domain.
3. Preserve and verify crawlable HTML, canonical metadata, robots directives,
   organization/site structured data, social preview metadata and sitemap.
4. Add one indexable public YouTube API review page that accurately states:
   website use is **no**, Android review-build use is **yes**, and iOS use is
   **no**; it also documents the active read-only/public-viewing boundary and
   the secure-review-access contact path.
5. Add the review page to the sitemap and automated public-site contracts.
6. Build and test the existing web app/static Firebase surface without
   changing the app, backend, Social provider implementation or protected APK.
7. Deploy only the verified static public-web files to the existing
   `moolsocial-dev-503018` Firebase Hosting live channel serving the public
   domain, then compare local and live artifacts and headers.
8. Verify the Search Console domain property through the authoritative
   Squarespace-managed DNS when the signed-in account exposes the verification
   token; submit the sitemap and request indexing for the canonical pages.
9. Prepare an unsent reply in the existing YouTube compliance thread that
   gives the three-platform answer, explains the private pre-launch Android
   build, and asks the reviewer to choose an accepted secure access mechanism
   if their preferred mechanism is not already stated.

## Explicit exclusions

- No Flutter, Android, iOS, Social runtime, provider API, backend, Firestore,
  Functions, payment or production-data changes.
- No new YouTube API method, scope, quota request or use-case expansion.
- No claim that the Android app is publicly listed in Google Play or that an
  iOS client exists.
- No public Git repository, public APK upload or uncontrolled pre-release
  binary link.
- No Production Firebase project creation, staging/production promotion or
  deployment of functions/backend resources.
- No edit to the read-only HTML screenbook.
- No email send until the founder approves the final reply text.
- No commit, push, merge, branch switch, cleanup or deletion.
- No change to the protected R58.8.8 FIX7 source, APK or install identities.

## Dependencies and approvals

- Founder authority is recorded in
  `docs/quality/WEB-MVP-PUBLIC-DISCOVERY-AND-YOUTUBE-REVIEW-ACCESS-AUTHORIZATION-20260805.md`.
- DNS writes require the signed-in Squarespace domain account and must be
  limited to exact records required for `www` and Search Console verification.
- Search Console submission requires verified ownership for
  `hello@moolsocial.com`; the verification value must be copied from Google and
  never invented.
- Firebase Hosting deployment must target only alias `dev`, project
  `moolsocial-dev-503018`, Hosting content `apps/web/public`, and no other
  Firebase resource.
- The separate OpenAI Sites binding must be inspected and preserved; it cannot
  silently replace the Firebase custom-domain authority.
- Giving reviewers a private Android build requires a reviewer-accepted secure
  distribution method and a usable reviewer identity. A public Play listing is
  not assumed to be required.
- Sending the Gmail reply remains a separate founder decision after review of
  the final draft.

## Test and evidence plan

1. Run the MVP execution gate for this exact ticket before source write/build.
2. Run the existing static-site tests, rendered-web tests, production web build
   and lint.
3. Add regression checks for the new page, its canonical/indexable metadata,
   platform-use statement, sitemap entry and absence of prohibited claims.
4. Verify local pages at narrow mobile and desktop widths, with no blocking
   console error or horizontal overflow.
5. After deployment, fetch apex and `www` from independent DNS/HTTP paths and
   with a Googlebot user agent; record status, redirects, TLS, headers,
   canonical URL, robots, sitemap and source-to-live hashes.
6. Record Search Console ownership, sitemap submission and URL-inspection/index
   request receipts when access is available; otherwise record the exact
   account/UI blocker without claiming completion.
7. Verify the YouTube draft against the actual Android package, Google Cloud
   project, review-build identity and currently active API methods/scopes.
8. Preserve all evidence under a new bounded quality-artifact directory and
   leave the protected Android release state unchanged.

## Founder disclosure record

Before execution, Codex disclosed the ticket ID/customer outcome,
`mvp_required` classification and reason, smallest scope, exclusions,
dependencies/approvals and test/evidence plan. The founder then directed:

> fix website seo issue it should be publically available by browsing , seo ,
> google search

and for the YouTube review:

> we will use youtube api only on mobile app ... if we can provide lets provide
> ... if technically we are not ready then give whatever possible explanation
> so they get satisfied or ask for more time

This is exact authority for the bounded remediation above. It does not broaden
the exclusions or waive any environment, provider, security or release gate.
