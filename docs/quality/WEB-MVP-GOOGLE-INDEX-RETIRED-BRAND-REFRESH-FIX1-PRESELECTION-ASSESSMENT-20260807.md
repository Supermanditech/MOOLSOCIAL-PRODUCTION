# Web MVP Google index retired-brand refresh FIX1 — preselection assessment

Date: 7 August 2026 IST
Ticket: `WEB-MVP-GOOGLE-INDEX-RETIRED-BRAND-REFRESH-FIX1`
Classification: `mvp_required`

## Customer outcome and classification

Google receives truthful freshness signals and an explicit reindex request so
the indexed MoolSocial Privacy result can replace the retired company identity
with current `moolsocial.com` copy. This is MVP-required because the founder's
live evidence confirms a public launch-identity regression in an already
supported and authorized discovery surface.

## Authority

The existing founder authorization in
`docs/quality/WEB-MVP-PUBLIC-DISCOVERY-AND-YOUTUBE-REVIEW-ACCESS-AUTHORIZATION-20260805.md`
explicitly covers bounded public-web source/build/deployment and exact Search
Console changes needed for public discovery. The founder's 7 August screenshot
is the exact escaped-defect continuation evidence.

Manifest:
`config/web-mvp-google-index-retired-brand-refresh-fix1-ticket.json`
Manifest SHA-256:
`EEC292516F4852E8DE077CE771EC40B8312CBA3C3151FBD1D80FF9A0E745E754`

## Robustness and reuse inventory

- Reuse the existing canonical `apps/web/public/sitemap.xml`; no new sitemap,
  route or discovery owner is necessary.
- Reuse `apps/web/tests/firebase-public-site.test.mjs`; strengthen its current
  stale-date assertion instead of creating another test family.
- Reuse the already verified Privacy canonical, robots directive, visible
  copy, Firebase Hosting project and Search Console domain-property workflow.
- Reuse the current hosting-only build/deploy path and seven-route public
  qualification. No Flutter, backend, provider or APK owner is touched.
- Duplicate search found no second canonical sitemap, public origin, Search
  Console property, route, screen, state service or deployment topology needed.

Implementation disposition: `reuse`, `configuration`,
`test_only_acceptance`.

New screens: none.
New routes: none.
New backend owners: none.
Timeline impact: zero engineering days; Google recrawl time remains externally
controlled and cannot be represented as engineering completion.

## Smallest complete implementation

1. Update all five significantly changed canonical sitemap `lastmod` values to
   `2026-08-07`.
2. Strengthen the existing sitemap regression assertion.
3. Run regression, MVP scope, build, tests and lint gates.
4. Deploy Firebase Hosting only to `moolsocial-dev-503018` and prove the live
   sitemap equals qualified local source.
5. With authorized property access, run Search Console live inspection for
   Privacy, request indexing and resubmit `https://moolsocial.com/sitemap.xml`.
6. Preserve the receipt or exact access blocker; never claim Google refreshed
   before observing the indexed result.

## Explicit exclusions

- No page removal, `noindex`, robots blocking or Outdated Content request.
- No DNS change under this exact ticket.
- No mobile, backend, Firestore, Functions, provider API or APK work.
- No Gmail or YouTube reply send.
- No promise of instant crawling, indexing, ranking or snippet replacement.
- No commit, push, merge, branch switch, cleanup or deletion.

## Acceptance evidence

- Screenshot retained with SHA-256 evidence.
- Permanent regression `REG-20260807-125` active.
- Exact sitemap date assertions and full public-site build/tests pass.
- Lint has zero errors.
- Googlebot-style Privacy fetch is indexable, canonical, current and free of
  every retired-name punctuation/spacing/case variant.
- Live sitemap is HTTP 200 and byte-identical to local source.
- Search Console receipts are recorded, or the exact verified access blocker
  remains explicit.

This assessment fits the locked 60–75-day robust MVP without changing route or
screen topology and without weakening any privacy, release or provider gate.
