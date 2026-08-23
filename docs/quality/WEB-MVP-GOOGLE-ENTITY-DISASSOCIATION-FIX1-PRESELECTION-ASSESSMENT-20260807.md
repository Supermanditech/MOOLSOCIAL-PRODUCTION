# Web MVP Google entity disassociation FIX1 — preselection assessment

Assessed: 7 August 2026
Ticket: `WEB-MVP-GOOGLE-ENTITY-DISASSOCIATION-FIX1`
Classification: `mvp_required`

## Customer outcome

Google is given the strongest safe owner-controlled signals to stop
cross-associating MoolSocial and SuperMandi while valid MoolSocial pages remain
discoverable.

This is required MVP public-identity remediation. The founder has clarified that
the two names represent separate entities and must not be linked through stale
MoolSocial-owned search results.

## Reuse and duplicate search

Reuse is complete:

- current MoolSocial production HTML already contains zero normalized
  retired-name matches across all seven verified public routes;
- the existing `sc-domain:moolsocial.com` Search Console property is accessible;
- the existing sitemap is live, successful and was resubmitted on 7 August;
- Privacy is already in Google's priority crawl queue;
- the existing public-web test, Hosting release owner, Search Console owner and
  permanent regression gate remain the only implementation owners.

No new screen, route, backend owner, Firebase project, deployment, schema or
service is necessary. Implementation disposition is exactly `reuse`,
`configuration` and `test_only_acceptance`.

## Confirmed current Google surface

Read-only live Google queries found three MoolSocial-owned canonical URLs with
stale retired-identity copies: Home, Privacy and YouTube API. The `moolsocial`
query AI Overview also derives an obsolete cross-entity statement. The source
pages are already corrected, so the smallest complete action is safe snippet
clearing plus reindex requests for the affected canonical URLs.

## Minimum complete scope

1. Reconfirm zero normalized retired-identity matches across current live public
   MoolSocial pages.
2. Preserve query evidence for `moolsocial`, exact `SuperMandi Tech Pvt Ltd`,
   and `site:moolsocial.com "SuperMandi Tech"`.
3. Select **Clear snippet in search** for exact Home, Privacy and YouTube API
   URLs in Search Console.
4. Do not select **Temporarily remove URL**.
5. Request indexing for Home and YouTube API; retain the accepted Privacy
   request rather than submitting it repeatedly.
6. Record exact receipts and correctly leave Google's search and AI refresh as
   provider-controlled pending work.

## Explicit exclusions

- no whole-URL removal, `noindex`, robots block, 404/410 or DNS change;
- no action against independent SuperMandi registry or third-party pages;
- no structured-data deception, cloaking or keyword manipulation;
- no web source or Firebase deploy unless a separate source defect is proved;
- no mobile, backend, APK, OPPO, Gmail, YouTube reply or provider feedback;
- no immediate result, AI Overview, crawl, ranking or snippet promise;
- no commit, push, merge, branch switch, cleanup or deletion.

## Robustness and 60–75 day lock

The ticket adds no product surface and no implementation owner. It reduces
public-identity risk through the already authorized Search Console control plane.
Timeline impact is zero delivery days. Existing protected APK, OPPO, mobile,
backend and dirty-workspace state remain untouched.

## Evidence plan

- three hashed Google query screenshots;
- normalized all-route live copy audit;
- exact Search Console snippet-clear receipts for three URLs;
- exact URL Inspection state for Home, Privacy and YouTube API;
- permanent regression and MVP scope gate closure.
