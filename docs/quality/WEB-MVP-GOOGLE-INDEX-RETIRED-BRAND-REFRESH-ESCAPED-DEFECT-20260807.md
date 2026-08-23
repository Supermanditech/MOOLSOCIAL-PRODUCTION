# Web MVP Google index retired-brand refresh — escaped defect

Date: 7 August 2026 IST
Observed by: founder Google Search screenshot
Screenshot SHA-256: `DB5A2702465A1443B74C4BA55C2790D42810D1AC799518104B0B3AF59116C383`

## Observation

Google Search showed the `https://moolsocial.com/privacy` result with a
26 July 2026 snippet containing `SuperMandi Tech Pvt Ltd`. The live Privacy
page already served `MoolSocial is a product of moolsocial.com`, its footer was
`© 2026 moolsocial.com`, and its no-cache HTTP response had a 7 August 2026
`Last-Modified` header.

## Escaped defect

The deployed sitemap still marked home, Privacy, Terms and Support as last
modified on 26 July and the YouTube API page as last modified on 5 August,
although the 7 August identity release significantly changed all five
canonical pages. The automated public-site test explicitly pinned those stale
dates. The prior ticket verified live HTML but did not reconcile Google's
indexed copy or crawl freshness signal before completion.

## Prevention and required correction

The exact successor ticket updates all five truthful sitemap `lastmod` values
to 7 August 2026, strengthens the automated test, redeploys Firebase Hosting
only, and verifies live sitemap/source equality. If the already-authorized
Search Console property is available, it then inspects and requests indexing
for Privacy and resubmits the sitemap. Google controls crawl timing, so a
submission receipt is evidence of the request—not proof of immediate snippet
replacement.

Permanent screenshot evidence:

`artifacts/quality/web-mvp-google-index-retired-brand-refresh-20260807-01/founder-google-search-stale-snippet.png`

## Selection-gate failure before source edit

The first successor assessment used `external_service_submission` as an
`implementationDisposition`. The delivery checker rejected it because that
closed enum permits only `reuse`, `configuration`, `thin_policy_adapter`,
`test_only_acceptance` and `new_necessary_work`. No sitemap or production
source was edited. The assessment must use only the copied supported set;
Search Console activity remains represented in scope, dependencies and
evidence rather than in a new machine enum.
